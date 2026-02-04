require 'spec_helper'
require 'active_model/validations/evatr_validator'

RSpec.describe ActiveModel::Validations::EvatrValidator do
  let(:check_class) { CanHazEvatr::RestCheck }
  let(:evat_result) do
    instance_double(
      CanHazEvatr::RestCheck,
      success: success,
      valid?: valid,
      errors: evat_errors
    )
  end
  let(:success) { true }
  let(:valid) { true }
  let(:evat_errors) { [] }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :vat_id, :full_name, :city, :street, :zip

      validates :vat_id, evatr: true

      def self.name
        'TestModel'
      end
    end
  end

  let(:record) do
    test_class.new(
      vat_id: 'PT123456789',
      full_name: 'Test Company',
      city: 'Berlin',
      street: 'Test Street',
      zip: '10111'
    )
  end

  before do
    allow(CanHazEvatr).to receive(:check_class).and_return(check_class)
    allow(check_class).to receive(:check_record).and_return(evat_result)
    check_class.config.job_class = nil
  end

  after do
    check_class.config.job_class = nil
  end

  describe 'validation without job_class' do
    it 'calls check_record with the record and vat value' do
      expect(check_class).to receive(:check_record).with(record, vat: 'PT123456789')
      record.valid?
    end

    context 'when check succeeds and is valid' do
      let(:success) { true }
      let(:valid) { true }

      it 'does not add errors' do
        record.valid?
        expect(record.errors[:vat_id]).to be_empty
      end
    end

    context 'when check fails (network error, etc.)' do
      let(:success) { false }

      it 'adds failure_evatr error' do
        record.valid?
        expect(record.errors[:vat_id]).to include(I18n.t('errors.messages.failure_evatr'))
      end

      it 'does not check validity or field errors' do
        expect(evat_result).not_to receive(:valid?)
        expect(evat_result).not_to receive(:errors)
        record.valid?
      end
    end

    context 'when check succeeds but VAT is invalid' do
      let(:success) { true }
      let(:valid) { false }

      it 'adds invalid_evatr error' do
        record.valid?
        expect(record.errors[:vat_id]).to include(I18n.t('errors.messages.invalid_evatr'))
      end
    end

    context 'when check succeeds but has field errors' do
      let(:success) { true }
      let(:valid) { true }
      let(:evat_errors) { [:city, :name] }

      it 'adds errors for each field' do
        record.valid?
        expect(record.errors[:vat_id]).to include(
          I18n.t('errors.messages.invalid_vat_city'),
          I18n.t('errors.messages.invalid_vat_name')
        )
      end
    end

    context 'when check succeeds but is invalid with field errors' do
      let(:success) { true }
      let(:valid) { false }
      let(:evat_errors) { [:street] }

      it 'adds both invalid_evatr and field errors' do
        record.valid?
        expect(record.errors[:vat_id]).to include(
          I18n.t('errors.messages.invalid_evatr'),
          I18n.t('errors.messages.invalid_vat_street')
        )
      end
    end
  end

  describe 'validation with job_class configured' do
    let(:job_class) { double('VatValidationJob') }

    before do
      check_class.config.job_class = 'VatValidationJob'
      stub_const('VatValidationJob', job_class)
    end

    it 'calls check_record' do
      allow(job_class).to receive(:perform_later)
      expect(check_class).to receive(:check_record).with(record, vat: 'PT123456789')
      record.valid?
    end

    it 'enqueues the job with record and attribute' do
      expect(job_class).to receive(:perform_later).with(record, :vat_id)
      record.valid?
    end

    it 'does not add validation errors' do
      allow(job_class).to receive(:perform_later)
      record.valid?
      expect(record.errors[:vat_id]).to be_empty
    end

    context 'even when check would fail' do
      let(:success) { false }

      it 'does not add errors (deferred to job)' do
        allow(job_class).to receive(:perform_later)
        record.valid?
        expect(record.errors[:vat_id]).to be_empty
      end
    end

    context 'even when VAT is invalid' do
      let(:valid) { false }
      let(:evat_errors) { [:city] }

      it 'does not add errors (deferred to job)' do
        allow(job_class).to receive(:perform_later)
        record.valid?
        expect(record.errors[:vat_id]).to be_empty
      end
    end
  end
end
