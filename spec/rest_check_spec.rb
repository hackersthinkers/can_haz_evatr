require 'spec_helper'

RSpec.describe CanHazEvatr::RestCheck do
  def rest_response_generator(hash = {})
    defaults = {
      id: 'd6f1148c48118a14',
      anfrageZeitpunkt: '2026-01-12T09:37:35.561855733+01:00',
      status: 'evatr-0000',
      ergFirmenname: 'A',
      ergStrasse: 'A',
      ergPlz: 'A',
      ergOrt: 'A'
    }.merge(hash)

    defaults.to_json
  end

  describe 'initialization' do
    subject { described_class.new }

    it 'has default configuration' do
      expect(subject.config.mapping).to be_a(Proc)
    end
  end

  describe '.check' do
    let(:response_body_hash) do
      {
        id: 'd6f1148c48118a14',
        anfrageZeitpunkt: '2026-01-12T09:37:35.561855733+01:00',
        status: 'evatr-0000',
        ergFirmenname: 'A',
        ergStrasse: 'A',
        ergPlz: 'A',
        ergOrt: 'A'
      }
    end
    let(:mock_response) { double('response', body: response_body_hash, success?: true) }

    before do
      described_class.config.requester_vat = 'DE123456789'
      allow_any_instance_of(described_class).to receive(:request).and_return(mock_response)
    end

    subject do
      described_class.check(
        vat: 'PT123456789',
        name: 'Test Company',
        city: 'Berlin',
        street: 'Test Street',
        zip: '10111'
      )
    end

    it 'creates an instance and performs check' do
      expect(subject).to be_a(described_class)
      expect(subject.success).to be(true)
    end

    it 'stores the response with merged angefragteUstid' do
      expected_response = response_body_hash.merge(angefragteUstid: 'PT123456789')
      expect(subject.response).to eq(expected_response.to_json)
    end
  end

  describe '.check_record' do
    let(:response_body_hash) do
      {
        id: 'd6f1148c48118a14',
        anfrageZeitpunkt: '2026-01-12T09:37:35.561855733+01:00',
        status: 'evatr-0000',
        ergFirmenname: 'A',
        ergStrasse: 'A',
        ergPlz: 'A',
        ergOrt: 'A'
      }
    end
    let(:mock_response) { double('response', body: response_body_hash, success?: true) }
    let(:record) do
      double('record',
        id: 1,
        class: 'TestRecord',
        full_name: 'Test Company',
        city: 'Berlin',
        street: 'Test Street',
        zip: '10111',
        persisted?: persisted
      )
    end
    let(:persisted) { false }

    before do
      described_class.config.requester_vat = 'DE123456789'
      described_class.config.recorder = nil
      allow_any_instance_of(described_class).to receive(:request).and_return(mock_response)
    end

    after do
      described_class.config.recorder = nil
    end

    subject { described_class.check_record(record, vat: 'PT123456789') }

    it 'calls check with vat and mapped record attributes' do
      expect(described_class).to receive(:check).with(
        vat: 'PT123456789',
        name: 'Test Company',
        city: 'Berlin',
        street: 'Test Street',
        zip: '10111'
      ).and_call_original

      subject
    end

    it 'returns a check instance' do
      expect(subject).to be_a(described_class)
      expect(subject.success).to be(true)
    end

    context 'with custom mapping' do
      before do
        described_class.config.mapping = ->(rec) {
          {
            name: rec.full_name.upcase,
            city: rec.city,
            street: rec.street,
            zip: rec.zip
          }
        }
      end

      after do
        described_class.config.mapping = ->(rec) {
          { name: rec.full_name, city: rec.city, street: rec.street, zip: rec.zip }
        }
      end

      it 'uses the custom mapping' do
        expect(described_class).to receive(:check).with(
          vat: 'PT123456789',
          name: 'TEST COMPANY',
          city: 'Berlin',
          street: 'Test Street',
          zip: '10111'
        ).and_call_original

        subject
      end
    end

    context 'when recorder is configured' do
      let(:recorder_class) { double('RecorderClass') }

      before do
        described_class.config.recorder = 'VatCheckRecord'
        allow_any_instance_of(described_class).to receive_message_chain(:config, :recorder).and_return('VatCheckRecord')
        stub_const('VatCheckRecord', recorder_class)
      end

      context 'and record is persisted' do
        let(:persisted) { true }

        it 'creates a recorder entry' do
          expect(recorder_class).to receive(:create).with(
            record_id: 1,
            record_type: 'TestRecord',
            response: anything
          )

          subject
        end
      end

      context 'and record is not persisted' do
        let(:persisted) { false }

        it 'does not create a recorder entry' do
          expect(recorder_class).not_to receive(:create)

          subject
        end
      end
    end

    context 'when recorder is not configured' do
      before do
        described_class.config.recorder = nil
      end

      let(:persisted) { true }

      it 'does not attempt to create a recorder entry' do
        expect(subject).to be_a(described_class)
      end
    end
  end

  describe '#valid?' do
    let(:response) { rest_response_generator(status: status) }

    subject { described_class.new(response: response, success: true) }

    context 'with evatr-0000 status' do
      let(:status) { 'evatr-0000' }

      it 'returns true' do
        expect(subject.valid?).to be(true)
      end
    end

    context 'with evatr-2002 status' do
      let(:status) { 'evatr-2002' }

      it 'returns false (valid_from_date is not strictly valid)' do
        expect(subject.valid?).to be(false)
      end
    end

    context 'with evatr-2006 status' do
      let(:status) { 'evatr-2006' }

      it 'returns false (previously_valid is not strictly valid)' do
        expect(subject.valid?).to be(false)
      end
    end

    context 'with evatr-2008 status' do
      let(:status) { 'evatr-2008' }

      it 'returns false (valid_with_notes is not strictly valid)' do
        expect(subject.valid?).to be(false)
      end
    end

    context 'with unknown status' do
      let(:status) { 'evatr-9999' }

      it 'returns false' do
        expect(subject.valid?).to be(false)
      end
    end
  end

  describe '#errors' do
    context 'when all fields match' do
      let(:response) { rest_response_generator }
      subject { described_class.new(response: response) }

      it 'returns empty array' do
        expect(subject.errors).to be_empty
      end
    end

    context 'when city does not match' do
      let(:response) do
        rest_response_generator(
          ergFirmenname: 'A',
          ergStrasse: 'A',
          ergPlz: 'A',
          ergOrt: 'B'
        )
      end
      subject { described_class.new(response: response) }

      it 'includes city in errors' do
        expect(subject.errors).to include(:city)
      end
    end

    context 'when multiple fields do not match' do
      let(:response) do
        rest_response_generator(
          ergFirmenname: 'B',
          ergStrasse: 'B',
          ergPlz: 'A',
          ergOrt: 'A'
        )
      end
      subject { described_class.new(response: response) }

      it 'includes both fields in errors' do
        expect(subject.errors).to include(:name, :street)
      end
    end
  end

  describe '#checked_vat_id' do
    let(:response) { rest_response_generator(angefragteUstid: 'FR12345678901') }
    subject { described_class.new(response: response) }

    it 'returns the checked VAT ID' do
      expect(subject.checked_vat_id).to eq('FR12345678901')
    end
  end

  describe '#results' do
    let(:response) do
      rest_response_generator(
        ergFirmenname: 'A',
        ergStrasse: 'B',
        ergPlz: 'A',
        ergOrt: 'C'
      )
    end
    subject { described_class.new(response: response) }

    it 'maps results correctly' do
      expect(subject.results).to eq(
        name: :ok,
        street: :no_match,
        zip: :ok,
        city: :not_provided
      )
    end
  end

  describe '#valid_from' do
    let(:response) { rest_response_generator(gueltigAb: '2026-02-01') }
    subject { described_class.new(response: response) }

    it 'returns the valid from date' do
      expect(subject.valid_from).to eq('2026-02-01')
    end
  end

  describe '#valid_to' do
    let(:response) { rest_response_generator(gueltigBis: '2026-12-31') }
    subject { described_class.new(response: response) }

    it 'returns the valid to date' do
      expect(subject.valid_to).to eq('2026-12-31')
    end
  end

  describe '#request_date' do
    let(:response) { rest_response_generator(datum: '2026-01-15') }
    subject { described_class.new(response: response) }

    it 'returns the request date' do
      expect(subject.request_date).to eq('2026-01-15')
    end
  end

  describe '#status_code' do
    let(:response) { rest_response_generator(status: 'evatr-2002') }
    subject { described_class.new(response: response) }

    it 'returns the status code' do
      expect(subject.status_code).to eq('evatr-2002')
    end
  end
end
