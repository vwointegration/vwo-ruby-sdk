# frozen_string_literal: true

require 'logger'

class VWO
  class CustomLogger
    @logger = nil
    @logger_instance = nil

    def self.get_instance(logger_instance = nil)
      @@logger ||= VWO::CustomLogger.new(logger_instance)
    end

    def initialize(logger_instance)
      @@logger_instance = logger_instance || Logger.new(STDOUT)
    end

    # Override this method to handle logs in a custom manner
    def log(level, message)
      @@logger_instance.log(level, message)
    end
  end
end
