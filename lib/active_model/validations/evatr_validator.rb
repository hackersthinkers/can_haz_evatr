require "can_haz_evatr/check"

module ActiveModel
  module Validations
    class EvatrValidator < EachValidator
      def validate_each(record, attribute, value)
        check_class = CanHazEvatr.check_class

        evat = check_class.check(
          vat: value,
          **check_class.config.mapping.call(record)
        )

        if evat.config.recorder && record.persisted?
          evat.config.recorder.constantize.create(record_id: record.id, record_type: record.class, response: evat.response)
        end

        unless evat.success
          record.errors.add(attribute, :failure_evatr)
          return
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
