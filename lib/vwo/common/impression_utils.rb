# frozen_string_literal: true

require 'json'
require 'cgi'
require_relative '../custom_logger'
require_relative 'enums'
require_relative 'constants'
require_relative 'function_utils'
require_relative 'uuid_utils'

# Utility module for manipulating VWO campaigns
class VWO
  module Common
    module ImpressionUtils
      include VWO::Common::Enums
      include VWO::Common::CONSTANTS
      include FunctionUtils
      include UUIDUtils

      # Trigger the goal by sending it to server
      #
      # @param[Hash]                        :settings_file          Settings file object
      # @param[String]                      :campaign_id            Campaign identifier
      # @param[String]                      :variation_id           Variation identifier
      # @param[String]                      :user_id                User identifier
      # @param[String]                      :goal_id                Goal identifier, if building track impression
      # @param[String|Float|Integer|nil)    :revenue                Number value, in any representation, if building track impression
      #
      # @return[nil|Hash]                                           None if campaign ID or variation ID is invalid,
      #                                                             Else Properties(dict)
      def build_event(settings_file, campaign_id, variation_id, user_id, goal_id = nil, revenue = nil)
        return unless valid_number?(campaign_id) && valid_string?(user_id)

        is_track_user_api = true
        is_track_user_api = false unless goal_id.nil?
        account_id = settings_file['accountId']

        properties = {
          account_id: account_id,
          experiment_id: campaign_id,
          ap: PLATFORM,
          uId: CGI.escape(user_id.encode('utf-8')),
          combination: variation_id,
          random: get_random_number,
          sId: get_current_unix_timestamp,
          u: generator_for(user_id, account_id)
        }
        # Version and SDK constants
        sdk_version = Gem.loaded_specs['vwo_sdk'] ? Gem.loaded_specs['vwo_sdk'].version : VWO::SDK_VERSION
        properties['sdk'] = 'ruby'
        properties['sdk-v'] = sdk_version

        url = HTTPS_PROTOCOL + ENDPOINTS::BASE_URL
        logger = VWO::CustomLogger.get_instance

        if is_track_user_api
          properties['ed'] = JSON.generate(p: 'server')
          properties['url'] = "#{url}#{ENDPOINTS::TRACK_USER}"
          logger.log(
            LogLevelEnum::DEBUG,
            format(
              LogMessageEnum::DebugMessages::IMPRESSION_FOR_TRACK_USER,
              file: FileNameEnum::ImpressionUtil,
              properties: JSON.generate(properties)
            )
          )
        else
          properties['url'] = url + ENDPOINTS::TRACK_GOAL
          properties['goal_id'] = goal_id
          properties['r'] = revenue if revenue
          logger.log(
            LogLevelEnum::DEBUG,
            format(
              LogMessageEnum::DebugMessages::IMPRESSION_FOR_TRACK_GOAL,
              file: FileNameEnum::ImpressionUtil,
              properties: JSON.generate(properties)
            )
          )
        end
        properties
      end
    end
  end
end
