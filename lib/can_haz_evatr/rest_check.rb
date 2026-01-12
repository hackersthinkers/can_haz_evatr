require "active_support/configurable"
require 'active_model'
require 'json'
require 'faraday'
require 'ostruct'

module CanHazEvatr
  class RestCheck
    FIELD_MAPPING = {
      'ergPlz' => :zip,
      'ergOrt' => :city,
      'ergFirmenname' => :name,
      'ergStrasse' => :street,
    }.freeze

    # New API uses evatr-XXXX codes
    STATUS_CODE_MAPPING = {
      'evatr-0000' => :valid,
      'evatr-2002' => :valid_from_date,
      'evatr-2006' => :previously_valid,
      'evatr-2008' => :valid_with_notes,
    }.freeze

    # Map API response values to result symbols (same as XML-RPC API)
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

      response = vat.request

      vat.response = response.body.to_json
      vat.success  = response.success?

      vat
    end

    def valid?
      return false unless parsed_response

      status = parsed_response['status']
      STATUS_CODE_MAPPING.key?(status) &&
        [:valid, :valid_from_date, :previously_valid, :valid_with_notes].include?(STATUS_CODE_MAPPING[status])
    end

    def errors
      return [] unless parsed_response

      results.select { |_, result| result == :no_match }.keys
    end

    def parsed_response
      @parsed_response ||= begin
        JSON.parse(response)
      rescue JSON::ParserError
        nil
      end
    end

    def error_code
      return nil unless parsed_response
      parsed_response['status']
    end

    def status_code
      error_code
    end

    def results
      return {} unless parsed_response

      FIELD_MAPPING.each_with_object({}) do |(field, mapped_field), hash|
        result_value = parsed_response[field]
        hash[mapped_field] = RESULT_MAPPING[result_value] if result_value
      end
    end

    def checked_vat_id
      parsed_response&.dig('angefragteUstid')
    end

    def valid_from
      parsed_response&.dig('gueltigAb')
    end

    def valid_to
      parsed_response&.dig('gueltigBis')
    end

    def request_date
      parsed_response&.dig('datum')
    end

    def request
      conn = Faraday.new(url: 'https://api.evatr.vies.bzst.de') do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end

      conn.post('/app/v1/abfrage') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          anfragendeUstid: config.requester_vat,
          angefragteUstid: vat,
          firmenname: name,
          strasse: street,
          plz: zip,
          ort: city
        }.compact
      end
    rescue Faraday::Error => e
      OpenStruct.new(body: { error: e.message }.to_json, success?: false)
    end
  end
end
