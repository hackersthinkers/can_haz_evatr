require "can_haz_evatr/version"
require "can_haz_evatr/check"

require 'active_model/validations/evatr_validator' if defined?(ActiveModel)

module CanHazEvatr
  class Error < StandardError; end
end
