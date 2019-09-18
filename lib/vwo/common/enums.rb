# frozen_string_literal: true

# rubocop:disable Metrics/LineLength

require 'logger'

class VWO
  module Common
    module Enums
      module FileNameEnum
        VWO_PATH = 'vwo'
        COMMON_PATH = 'vwo/common'

        VWO = VWO_PATH + '/vwo'
        BucketingService = VWO_PATH + '/bucketing_service'
        DecisionService = VWO_PATH + '/decision_service'
        EventDispatcher = VWO_PATH + '/event_dispatcher'
        Logger = VWO_PATH + '/logger'
        ProjectConfigManager = VWO_PATH + '/project_config_manager'

        CampaignUtil = COMMON_PATH + '/campaign_util'
        FunctionUtil = COMMON_PATH + '/function_util'
        ImpressionUtil = COMMON_PATH + '/impression_util'
        UuidUtil = COMMON_PATH + '/uuid_util'
        ValidateUtil = COMMON_PATH + '/validate_util'
      end

      # Classobj encapsulating various logging messages
      module LogMessageEnum
        # Classobj encapsulating various DEBUG messages
        module DebugMessages
          LOG_LEVEL_SET = '(%<file>s): Log level set to %<level>s'
          SET_COLORED_LOG = '(%<file>s): Colored log set to %<value>s'
          SET_DEVELOPMENT_MODE = '(%<file>s): DEVELOPMENT mode is ON'
          VALID_CONFIGURATION = '(%<file>s): SDK configuration and account settings are valid.'
          CUSTOM_LOGGER_USED = '(%<file>s): Custom logger used'
          SDK_INITIALIZED = '(%<file>s): SDK properly initialized'
          SETTINGS_FILE_PROCESSED = '(%<file>s): Settings file processed'
          NO_STORED_VARIATION = '(%<file>s): No stored variation for UserId:%<user_id>s for Campaign:%<campaign_test_key>s found in UserProfileService'
          NO_USER_PROFILE_SERVICE_LOOKUP = '(%<file>s): No UserProfileService to look for stored data'
          NO_USER_PROFILE_SERVICE_SAVE = '(%<file>s): No UserProfileService to save data'
          GETTING_STORED_VARIATION = '(%<file>s): Got stored variation for UserId:%<user_id>s of Campaign:%<campaign_test_key>s as Variation: %<variation_name>s found in UserProfileService'
          CHECK_USER_ELIGIBILITY_FOR_CAMPAIGN = '(%<file>s): campaign:%<campaign_test_key>s having traffic allocation:%<traffic_allocation>s assigned value:%<traffic_allocation>s to userId:%<user_id>s'
          USER_HASH_BUCKET_VALUE = '(%<file>s): userId:%<user_id>s having hash:%<hash_value>s got bucketValue:%<bucket_value>s'
          VARIATION_HASH_BUCKET_VALUE = '(%<file>s): userId:%<user_id>s for campaign:%<campaign_test_key>s having percent traffic:%<percent_traffic>s got hash-value:%<hash_value>s and bucket value:%<bucket_value>s'
          IMPRESSION_FAILED = '(%<file>s): userId:%<user_id>s for campaign:%<campaign_test_key>s got variationName:%<variation_name>s inside method:%<method>s'
          USER_NOT_PART_OF_CAMPAIGN = '(%<file>s): userId:%<user_id>s for campaign:%<campaign_test_key>s did not become part of campaign method:%<method>s'
          UUID_FOR_USER = '(%<file>s): Uuid generated for userId:%<user_id>s and accountId:%<account_id>s is %<desired_uuid>s'
          IMPRESSION_FOR_TRACK_USER = '(%<file>s): Impression built for track-user - %<properties>s'
          IMPRESSION_FOR_TRACK_GOAL = '(%<file>s): Impression built for track-goal - %<properties>s'
          GOT_VARIATION_FOR_USER = '(%<file>s): userId:%<user_id>s for campaign:%<campaign_test_key>s got variationName:%<variation_name>s'
        end

        # Classobj encapsulating various INFO messages
        module InfoMessages
          VARIATION_RANGE_ALLOCATION = '(%<file>s): Campaign:%<campaign_test_key>s having variations:%<variation_name>s with weight:%<variation_weight>s got range as: ( %<start>s - %<end>s ))'
          VARIATION_ALLOCATED = '(%<file>s): UserId:%<user_id>s of Campaign:%<campaign_test_key>s got variation: %<variation_name>s'
          LOOKING_UP_USER_PROFILE_SERVICE = '(%<file>s): Looked into UserProfileService for userId:%<user_id>s %<status>s'
          SAVING_DATA_USER_PROFILE_SERVICE = '(%<file>s): Saving into UserProfileService for userId:%<user_id>s successful'
          GOT_STORED_VARIATION = '(%<file>s): Got stored variation:%<variation_name>s of campaign:%<campaign_test_key>s for userId:%<user_id>s from UserProfileService'
          NO_VARIATION_ALLOCATED = '(%<file>s): UserId:%<user_id>s of Campaign:%<campaign_test_key>s did not get any variation'
          USER_ELIGIBILITY_FOR_CAMPAIGN = '(%<file>s): Is userId:%<user_id>s part of campaign? %<is_user_part>s'
          AUDIENCE_CONDITION_NOT_MET = '(%<file>s): userId:%<user_id>s does not become part of campaign because of not meeting audience conditions'
          GOT_VARIATION_FOR_USER = '(%<file>s): userId:%<user_id>s for campaign:%<campaign_test_key>s got variationName:%<variation_name>s'
          USER_GOT_NO_VARIATION = '(%<file>s): userId:%<user_id>s for campaign:%<campaign_test_key>s did not allot any variation'
          IMPRESSION_SUCCESS = '(%<file>s): Impression event - %<end_point>s was successfully received by VWO having main keys: accountId:%<account_id>s userId:%<user_id>s campaignId:%<campaign_id>s and variationId:%<variation_id>s'
          INVALID_VARIATION_KEY = '(%<file>s): Variation was not assigned to userId:%<user_id>s for campaign:%<campaign_test_key>s'
          RETRY_FAILED_IMPRESSION_AFTER_DELAY = '(%<file>s): Failed impression event for %<end_point>s will be retried after %<retry_timeout>s milliseconds delay'
        end

        # Classobj encapsulating various WARNING messages
        module WarningMessages; end

        # Classobj encapsulating various ERROR messages
        module ErrorMessages
          PROJECT_CONFIG_CORRUPTED = '(%<file>s): config passed to createInstance is not a valid JSON object.'
          INVALID_CONFIGURATION = '(%<file>s): SDK configuration or account settings or both is/are not valid.'
          SETTINGS_FILE_CORRUPTED = '(%<file>s): Settings file is corrupted. Please contact VWO Support for help.'
          ACTIVATE_API_MISSING_PARAMS = '(%<file>s): "activate" API got bad parameters. It expects campaignTestKey(String) as first and userId(String) as second argument'
          ACTIVATE_API_CONFIG_CORRUPTED = '(%<file>s): "activate" API has corrupted configuration'
          GET_VARIATION_API_MISSING_PARAMS = '(%<file>s): "getVariation" API got bad parameters. It expects campaignTestKey(String) as first and userId(String) as second argument'
          GET_VARIATION_API_CONFIG_CORRUPTED = '(%<file>s): "getVariation" API has corrupted configuration'
          TRACK_API_MISSING_PARAMS = '(%<file>s): "track" API got bad parameters. It expects campaignTestKey(String) as first userId(String) as second and goalIdentifier(String/Number) as third argument. Fourth is revenueValue(Float/Number/String) and is required for revenue goal only.'
          TRACK_API_CONFIG_CORRUPTED = '(%<file>s): "track" API has corrupted configuration'
          TRACK_API_GOAL_NOT_FOUND = '(%<file>s): Goal:%<goal_identifier>s not found for campaign:%<campaign_test_key>s and userId:%<user_id>s'
          TRACK_API_REVENUE_NOT_PASSED_FOR_REVENUE_GOAL = '(%<file>s): Revenue value should be passed for revenue goal:%<goal_identifier>s for campaign:%<campaign_test_key>s and userId:%<user_id>s'
          TRACK_API_VARIATION_NOT_FOUND = '(%<file>s): Variation not found for campaign:%<campaign_test_key>s and userId:%<user_id>s'
          CAMPAIGN_NOT_RUNNING = '(%<file>s): API used:%<api>s - Campaign:%<campaign_test_key>s is not RUNNING. Please verify from VWO App'
          LOOK_UP_USER_PROFILE_SERVICE_FAILED = '(%<file>s): Looking data from UserProfileService failed for userId:%<user_id>s'
          SAVE_USER_PROFILE_SERVICE_FAILED = '(%<file>s): Saving data into UserProfileService failed for userId:%<user_id>s'
          INVALID_CAMPAIGN = '(%<file>s): Invalid campaign passed to %<method>s of this file'
          INVALID_USER_ID = '(%<file>s): Invalid userId:%<user_id>s passed to %<method>s of this file'
          IMPRESSION_FAILED = '(%<file>s): Impression event could not be sent to VWO - %<end_point>s'
          CUSTOM_LOGGER_MISCONFIGURED = '(%<file>s): Custom logger is provided but seems to have mis-configured. %<extra_info>s Please check the API Docs. Using default logger.'
        end
      end

      module LogLevelEnum
        INFO = Logger::INFO
        DEBUG = Logger::DEBUG
        WARNING = Logger::WARN
        ERROR = Logger::ERROR
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
