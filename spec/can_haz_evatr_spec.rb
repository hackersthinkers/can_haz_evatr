require 'spec_helper'

RSpec.describe CanHazEvatr do
  def param_generator(hash = {})
    defaults = {
      result: 200,
      city: 'Berlin',
      city_result: 'A',
      name: 'Kitty Kit',
      name_result: 'A',
      street: 'Cheese Street',
      street_result: 'A',
      zip: '10111',
      zip_result: 'A',
    }.merge(hash)

    ERB.new(File.read(File.join('spec', 'fixtures', 'param.xml.erb'))).result_with_hash(defaults)
  end

  it "has a version number" do
    expect(CanHazEvatr::VERSION).not_to be nil
  end

  describe CanHazEvatr::Check do
    let(:response) { param_generator }

    subject { described_class.new(response: response) }

    it 'may haz no errors' do
      expect(subject.errors).to be_empty
    end

    describe '#errors' do
      let(:response) { param_generator(city_result: 'B') }

      it 'may find the fields with errors' do
        expect(subject.errors).to include(:city)
      end
    end

    describe '#valid?' do
      let(:response) { param_generator(result: '200') }

      it 'may be invalid' do
        expect(subject.valid?).to be(true)
      end

      describe 'with error code above 200' do
        let(:response) { param_generator(result: '201') }

        it 'will be invalid' do
          expect(subject.valid?).to be(false)
        end
      end
    end

    describe '#checked_vat_id' do
      let(:response) { param_generator }

      it 'may find the fields with errors' do
        expect(subject.checked_vat_id).to eq('PTXXXXXXXX')
      end
    end

  end
end
