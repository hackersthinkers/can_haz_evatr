require 'spec_helper'

RSpec.describe 'Configuration API Switch' do
  after do
    # Reset to default after each test
    CanHazEvatr.use_rest_api = false
  end

  describe 'CanHazEvatr.check_class' do
    context 'when use_rest_api is false (default)' do
      it 'returns Check class' do
        CanHazEvatr.use_rest_api = false
        expect(CanHazEvatr.check_class).to eq(CanHazEvatr::Check)
      end
    end

    context 'when use_rest_api is true' do
      it 'returns RestCheck class' do
        CanHazEvatr.use_rest_api = true
        expect(CanHazEvatr.check_class).to eq(CanHazEvatr::RestCheck)
      end
    end

    context 'when use_rest_api is nil (default state)' do
      it 'returns Check class' do
        # use_rest_api? defaults to false
        expect(CanHazEvatr.check_class).to eq(CanHazEvatr::Check)
      end
    end
  end

  describe 'Module-level configuration' do
    it 'has use_rest_api as a module accessor' do
      expect(CanHazEvatr).to respond_to(:use_rest_api)
      expect(CanHazEvatr).to respond_to(:use_rest_api=)
    end

    it 'allows setting requester_vat in Check config' do
      CanHazEvatr::Check.config.requester_vat = 'DE123456789'
      expect(CanHazEvatr::Check.config.requester_vat).to eq('DE123456789')
    end

    it 'keeps API version separate from class-specific config' do
      CanHazEvatr.use_rest_api = true
      CanHazEvatr::Check.config.requester_vat = 'DE111111111'
      CanHazEvatr::RestCheck.config.requester_vat = 'DE222222222'

      expect(CanHazEvatr.use_rest_api).to eq(true)
      expect(CanHazEvatr::Check.config.requester_vat).to eq('DE111111111')
      expect(CanHazEvatr::RestCheck.config.requester_vat).to eq('DE222222222')
    end
  end
end
