require "can_haz_evatr/check"

module ActiveModel
  module Validations
    class EvatrValidator < EachValidator
      def validate_each(record, attribute, value)
        evat = CanHazEvatr::Check.check(
          vat: value,
          **CanHazEvatr::Check.config.mapping.call(record)
        )

        if evat.config.recorder
          evat.recorder.constantize.create(record: record, response: evat.response)
        end

        record.errors.add(attribute, :invalid_evatr) unless evat.valid?

        evat.errors.each do |error|
          record.errors.add(attribute, :"invalid_vat_#{error}")
        end
      end
    end
  end
end

I18n.load_path += Dir["#{File.dirname(__FILE__)}/../../can_haz_evatr/locales/*.yml"]
