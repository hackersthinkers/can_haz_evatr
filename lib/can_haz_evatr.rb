require "can_haz_evatr/version"
require 'faraday'
require 'active_support'
require 'active_model'
require "can_haz_evatr/check"
require "can_haz_evatr/rest_check"

require 'active_model/validations/evatr_validator' if defined?(ActiveModel)

module CanHazEvatr
  class Error < StandardError; end

  class << self
    attr_accessor :use_rest_api

    def use_rest_api?
      @use_rest_api ||= false
    end

    def check_class
      use_rest_api? ? RestCheck : Check
    end
  end
end
