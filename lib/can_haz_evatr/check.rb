require "active_support/configurable"
require 'active_model'
require 'nokogiri'

module CanHazEvatr
   class Check
    FIELD_MAPPING = {
      'Erg_PLZ' => :zip,
      'Erg_Ort' => :city,
      'Erg_Name' => :name,
      'Erg_Str' => :street,
    }.freeze

    RESULT_MAPPING = {
      'A' => :ok,
      'B' => :no_match,
      'C' => :not_provided,
      'D' => :not_reported,
    }.freeze

    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveSupport::Configurable

    config_accessor :requester_vat, :recorder, :mapping

    self.config.mapping = ->(record) {
      {
        name:   record.full_name,
        city:   record.city,
        street: record.street,
        zip:    record.zip
      }
    }

    attr_accessor :vat, :name, :city, :street, :zip

    attribute :response, :string, default: ''
    attribute :success, :boolean, default: false

    def self.check(vat:, name:, city:, street:, zip:)
      vat = new(vat: vat, name: name, city: city, street: street, zip: zip)

      vat.response = vat.request.body
      vat.success  = vat.request.success?

      vat
    end

    def valid?
      error_code == 200
    end

    def errors
      results.select { |_,v| v == :no_match }.keys
    end

    def parsed
      @parsed ||= Nokogiri::XML(response) { |config| config.noblanks }
    end

    def error_code
      parsed.at_xpath('//data[value/string = "ErrorCode"]')&.elements&.last&.text.to_i
    end

    def results
      parsed.xpath('//*[value/string[contains(text(), "Erg")]]').
        each_with_object({}) do |result, hash|
          hash[FIELD_MAPPING[result.elements.first.text]] = RESULT_MAPPING[result.elements.last.text]
        end
    end

    def checked_vat_id
      parsed.at_xpath('//data[value/string = "UstId_2"]')&.elements&.last&.text
    end

    def request
      @request ||= Faraday.post('https://evatr.bff-online.de/evatrRPC', {
        UstId_1:     config.requester_vat,
        UstId_2:     vat,
        Firmenname:  name,
        Ort:         city,
        PLZ:         zip,
        Strasse:     street
      })
    end
  end
end

