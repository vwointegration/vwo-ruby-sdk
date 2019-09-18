# frozen_string_literal: true

require_relative 'custom_logger'
require_relative 'common/enums'
require_relative 'common/requests'

# Module for dispatching events to the server.
class VWO
  class EventDispatcher
    include VWO::Common::Enums

    EXCLUDE_KEYS = ['url'].freeze

    # Initialize the dispatcher with logger
    #
    # @param [Boolean] :  To specify whether the request
    #                     to our server should be made or not.
    #
    def initialize(is_development_mode = false)
      @logger = CustomLogger.get_instance
      @is_development_mode = is_development_mode
    end

    # Dispatch the event being represented in the properties object.
    #
    # @param[Hash]        :properties       Object holding information about
    #                                       the request to be dispatched to the VWO backend.
    # @return[Boolean]
    #
    def dispatch(properties)
      return true if @is_development_mode

      modified_properties = properties.reject do |key, _value|
        EXCLUDE_KEYS.include?(key)
      end

      resp = VWO::Common::Requests.get(properties['url'], modified_properties)
      if resp.code == '200'
        @logger.log(
          LogLevelEnum::INFO,
          format(
            LogMessageEnum::InfoMessages::IMPRESSION_SUCCESS,
            file: FileNameEnum::EventDispatcher,
            end_point: properties[:url],
            campaign_id: properties[:experiment_id],
            user_id: properties[:uId],
            account_id: properties[:account_id],
            variation_id: properties[:combination]
          )
        )
        return true
      else
        @logger.log(
          LogLevelEnum::ERROR,
          format(LogMessageEnum::ErrorMessages::IMPRESSION_FAILED, file: FileNameEnum.EventDispatcher, end_point: properties['url'])
        )
        return false
      end
    rescue StandardError
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::IMPRESSION_FAILED, file: FileNameEnum::EventDispatcher, end_point: properties['url'])
      )
      false
    end
  end
end
