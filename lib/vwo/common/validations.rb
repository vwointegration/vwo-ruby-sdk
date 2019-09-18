# frozen_string_literal: true

require 'json'
require 'json-schema'
require_relative 'schemas/settings_file'

class VWO
  module Common
    module Validations
      UTILITIES = {
        'logger' => ['log'],
        'event_dispatcher' => ['dispatch'],
        'user_profile_service' => %w[lookup save]
      }.freeze
      # Validates the project settings_file
      # @param [Hash]:  JSON object received from DACDN server or somewhere else,
      #                 must be json string representation.
      # @return [Boolean]
      def valid_settings_file?(settings_file)
        settings_file = JSON.parse(settings_file)
        JSON::Validator.validate!(VWO::Common::Schema::SETTINGS_FILE_SCHEMA, settings_file)
      rescue StandardError
        false
      end

      # @return [Boolean]
      def valid_value?(val)
        !val.nil?
      end

      # @return [Boolean]
      def valid_number?(val)
        val.is_a?(Numeric)
      end

      # @return [Boolean]
      def valid_string?(val)
        val.is_a?(String)
      end

      # @return [Boolean]
      def valid_hash?(val)
        val.is_a?(Hash)
      end

      # @param [Class] - User defined class instance
      # @param [utility_name] - Name of the utility
      # @return [Boolean]
      def valid_utility?(utility, utility_name)
        utility_attributes = UTILITIES[utility_name]
        return false if utility_attributes.nil?

        utility_attributes.each do |attr|
          return false unless method?(utility, attr)
        end
        true
      end

      private

      # @return [Boolean]
      def method?(object, method)
        object.methods.include?(method.to_sym)
      end
    end
  end
end
