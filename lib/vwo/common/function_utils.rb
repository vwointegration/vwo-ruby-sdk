# frozen_string_literal: true

require_relative '../custom_logger'
require_relative 'enums'
require_relative 'constants'

# Utility module for manipulating VWO campaigns
class VWO
  module Common
    module FunctionUtils
      include VWO::Common::Enums
      include VWO::Common::CONSTANTS

      # @return[Float]
      def get_random_number
        rand
      end

      # @return[Integer]
      def get_current_unix_timestamp
        Time.now.to_i
      end
    end
  end
end
