require 'spec_helper'

RSpec.describe CanHazEvatr::RestCheck, 'with actual API response' do
  let(:actual_response) do
    {
      "id" => "d6f1148c48118a14",
      "anfrageZeitpunkt" => "2026-01-12T09:37:35.561855733+01:00",
      "status" => "evatr-0000",
      "ergFirmenname" => "A",
      "ergStrasse" => "A",
      "ergPlz" => "A",
      "ergOrt" => "A"
    }.to_json
  end

  subject { described_class.new(response: actual_response, success: true) }

  describe '#valid?' do
    it 'returns true for evatr-0000 status with all A results' do
      expect(subject.valid?).to be(true)
    end
  end

  describe '#errors' do
    it 'returns empty array when all fields match (A)' do
      expect(subject.errors).to be_empty
    end
  end

  describe '#results' do
    it 'maps all fields to :ok' do
      expect(subject.results).to eq(
        name: :ok,
        street: :ok,
        zip: :ok,
        city: :ok
      )
    end
  end

  describe '#status_code' do
    it 'returns the status code' do
      expect(subject.status_code).to eq('evatr-0000')
    end
  end

  context 'with some non-matching fields' do
    let(:actual_response) do
      {
        "id" => "d6f1148c48118a14",
        "anfrageZeitpunkt" => "2026-01-12T09:37:35.561855733+01:00",
        "status" => "evatr-0000",
        "ergFirmenname" => "B",
        "ergStrasse" => "A",
        "ergPlz" => "B",
        "ergOrt" => "A"
      }.to_json
    end

    it 'is still valid (VAT ID is valid)' do
      expect(subject.valid?).to be(true)
    end

    it 'reports errors for non-matching fields' do
      expect(subject.errors).to contain_exactly(:name, :zip)
    end

    it 'maps results correctly' do
      expect(subject.results).to eq(
        name: :no_match,
        street: :ok,
        zip: :no_match,
        city: :ok
      )
    end
  end

  context 'with not provided fields (C)' do
    let(:actual_response) do
      {
        "id" => "d6f1148c48118a14",
        "anfrageZeitpunkt" => "2026-01-12T09:37:35.561855733+01:00",
        "status" => "evatr-0000",
        "ergFirmenname" => "A",
        "ergStrasse" => "C",
        "ergPlz" => "C",
        "ergOrt" => "A"
      }.to_json
    end

    it 'maps C to :not_provided' do
      expect(subject.results).to eq(
        name: :ok,
        street: :not_provided,
        zip: :not_provided,
        city: :ok
      )
    end

    it 'does not include not_provided fields in errors' do
      expect(subject.errors).to be_empty
    end
  end
end
