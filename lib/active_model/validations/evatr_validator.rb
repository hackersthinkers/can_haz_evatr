require "can_haz_evatr/check"

module ActiveModel
  module Validations
    class EvatrValidator < EachValidator
      def validate_each(record, attribute, value)
        check_class = CanHazEvatr.check_class

        evat = check_class.check_record(record, vat: value)

        if check_class.config.job_class
          check_class.config.job_class.constantize.perform_later(record, attribute)
        else
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
end

I18n.load_path += Dir["#{File.dirname(__FILE__)}/../../can_haz_evatr/locales/*.yml"]
