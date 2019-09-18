# frozen_string_literal: true

require_relative 'vwo/get_settings'
require_relative 'vwo/custom_logger'
require_relative 'vwo/common/utils'
require_relative 'vwo/common/enums'
require_relative 'vwo/common/campaign_utils'
require_relative 'vwo/common/impression_utils'
require_relative 'vwo/common/constants'
require_relative 'vwo/project_config_manager'
require_relative 'vwo/decision_service'
require_relative 'vwo/event_dispatcher'

# Class encapsulating all SDK functionality.
class VWO
  attr_accessor :is_valid

  include Common::Enums
  include Common::Validations
  include Common::CampaignUtils
  include Common::ImpressionUtils
  include Common::CONSTANTS

  FILE = FileNameEnum::VWO

  # VWO init method for managing custom projects.
  # Setting various services on the instance
  # To be accessible by its member functions
  #
  # @param[Numeric|String]  :account_id             Account Id in VWO
  # @param[String]          :sdk_key                Unique sdk key for user,
  #                                                 can be retrieved from our website
  # @param[Object]          :logger                 Optional component which provides a log method
  #                                                 to log messages. By default everything would be logged.
  # @param[Object]          :user_profile_service   Optional component which provides
  #                                                 methods to store and manage user profiles.
  # @param[Boolean]         :is_development_mode    To specify whether the request
  #                                                 to our server should be sent or not.
  # @param[String]          :settings_file          Settings File Content if already present

  def initialize(
    account_id,
    sdk_key,
    logger = nil,
    user_profile_service = nil,
    is_development_mode = false,
    settings_file = nil
  )
    @account_id = account_id
    @sdk_key = sdk_key
    @user_profile_service = user_profile_service
    @is_development_mode = is_development_mode

    # Verify and assign a/the logger (Pending)
    @logger = CustomLogger.get_instance(logger)
    # Verify the settings_file for json object and correct schema

    unless valid_settings_file?(get_settings(settings_file))
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::SETTINGS_FILE_CORRUPTED, file: FILE)
      )
      @is_valid = false
      return
    end
    @is_valid = true

    # Initialize the ProjectConfigManager if settings_file provided is valid
    @config = VWO::ProjectConfigManager.new(get_settings)

    @logger.log(
      LogLevelEnum::DEBUG,
      format(LogMessageEnum::DebugMessages::VALID_CONFIGURATION, file: FILE)
    )

    # Process the settings file
    @config.process_settings_file
    @settings_file = @config.get_settings_file

    # Assign DecisionService to vwo
    @decision_service = DecisionService.new(@settings_file, user_profile_service)

    # Assign event dispatcher
    if is_development_mode
      @logger.log(
        LogLevelEnum::DEBUG,
        format(LogMessageEnum::DebugMessages::SET_DEVELOPMENT_MODE, file: FILE)
      )
    end
    @event_dispatcher = EventDispatcher.new(is_development_mode)

    # Log successfully initialized SDK
    @logger.log(
      LogLevelEnum::DEBUG,
      format(LogMessageEnum::DebugMessages::SDK_INITIALIZED, file: FILE)
    )
  end

  # VWO get_settings method to get settings for a particular account_id
  # It will memoize the settings to avoid another http call on re-invocation of this method
  def get_settings(settings_file = nil)
    @settings ||=
      settings_file || VWO::GetSettings.new(@account_id, @sdk_key).get
    @settings
  end

  # This API method: Gets the variation assigned for the user
  # For the campaign and send the metrics to VWO server
  #
  # 1. Validates the arguments being passed
  # 2. Checks if user is eligible to get bucketed into the campaign,
  # 3. Assigns the deterministic variation to the user(based on userId),
  #    If user becomes part of campaign
  #    If userProfileService is used, it will look into it for the
  #    Variation and if found, no further processing is done
  # 4. Sends an impression call to VWO server to track user
  #
  # @param[String]            :campaign_test_key  Unique campaign test key
  # @param[String]            :user_id            ID assigned to a user
  # @return[String|None]                          If variation is assigned then variation-name
  #                                               otherwise None in case of user not becoming part

  def activate(campaign_test_key, user_id)
    # Validate input parameters
    unless valid_string?(campaign_test_key) && valid_string?(user_id)
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::ACTIVATE_API_MISSING_PARAMS, file: FILE)
      )
      return
    end

    # Validate project config manager
    unless @is_valid
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::ACTIVATE_API_CONFIG_CORRUPTED, file: FILE)
      )
      return
    end

    # Get the campaign settings
    campaign = get_campaign(@settings_file, campaign_test_key)

    # Validate campaign
    unless campaign && campaign['status'] == STATUS_RUNNING
      # Campaign is invalid
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::CAMPAIGN_NOT_RUNNING, file: FILE, campaign_test_key: campaign_test_key, api: 'activate')
      )
      return
    end

    # Once the matching RUNNING campaign is found, assign the
    # deterministic variation to the user_id provided
    variation_id, variation_name = @decision_service.get(
      user_id,
      campaign,
      campaign_test_key
    )

    # Check if variation_name has been assigned
    unless valid_value?(variation_name)
      # log invalid variation key
      @logger.log(
        LogLevelEnum::INFO,
        format(LogMessageEnum::InfoMessages::INVALID_VARIATION_KEY, file: FILE, user_id: user_id, campaign_test_key: campaign_test_key)
      )
      return
    end

    # Variation found, dispatch log to DACDN
    properties = build_event(
      @settings_file,
      campaign['id'],
      variation_id,
      user_id
    )
    @event_dispatcher.dispatch(properties)
    variation_name
  end

  # This API method: Gets the variation assigned for the
  # user for the campaign
  #
  # 1. Validates the arguments being passed
  # 2. Checks if user is eligible to get bucketed into the campaign,
  # 3. Assigns the deterministic variation to the user(based on user_id),
  #    If user becomes part of campaign
  #    If userProfileService is used, it will look into it for the
  #    variation and if found, no further processing is done
  #
  # @param[String]              :campaign_test_key        Unique campaign test key
  # @param[String]              :user_id                  ID assigned to a user
  #
  # @@return[String|Nil]                                  If variation is assigned then variation-name
  #                                                       Otherwise null in case of user not becoming part
  #
  def get_variation(campaign_test_key, user_id)
    # Check for valid arguments
    unless valid_string?(campaign_test_key) && valid_string?(user_id)
      # log invalid params
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::GET_VARIATION_API_MISSING_PARAMS, file: FILE)
      )
      return
    end

    # Validate project config manager
    unless @is_valid
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::ACTIVATE_API_CONFIG_CORRUPTED, file: FILE)
      )
      return
    end

    # Get the campaign settings
    campaign = get_campaign(@settings_file, campaign_test_key)

    # Validate campaign
    if campaign.nil? || campaign['status'] != STATUS_RUNNING
      # log campaigns invalid
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::CAMPAIGN_NOT_RUNNING, file: FILE, campaign_test_key: campaign_test_key, api: 'get_variation')
      )
      return
    end

    _variation_id, variation_name = @decision_service.get(
      user_id,
      campaign,
      campaign_test_key
    )

    # Check if variation_name has been assigned
    unless valid_value?(variation_name)
      # log invalid variation key
      @logger.log(
        LogLevelEnum::INFO,
        format(LogMessageEnum::InfoMessages::INVALID_VARIATION_KEY, file: FILE, user_id: user_id, campaign_test_key: campaign_test_key)
      )
      return
    end

    variation_name
  end

  # This API method: Marks the conversion of the campaign
  # for a particular goal
  # 1. validates the arguments being passed
  # 2. Checks if user is eligible to get bucketed into the campaign,
  # 3. Gets the assigned deterministic variation to the
  #     user(based on user_d), if user becomes part of campaign
  # 4. Sends an impression call to VWO server to track goal data
  #
  # @param[String]                      :campaign_test_key        Unique campaign test key
  # @param[String]                      :user_id                  ID assigned to a user
  # @param[String]                      :goal_identifier          Unique campaign's goal identifier
  # @param[Numeric|String]              :revenue_value            Revenue generated on triggering the goal
  #
  def track(campaign_test_key, user_id, goal_identifier, *args)
    if args.is_a?(Array)
      revenue_value = args[0]
    elsif args.is_a?(Hash)
      revenue_value = args['revenue_value']
    end

    # Check for valid args
    unless valid_string?(campaign_test_key) && valid_string?(user_id) && valid_string?(goal_identifier)
      # log invalid params
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::TRACK_API_MISSING_PARAMS, file: FILE)
      )
      return false
    end

    unless @is_valid
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::ACTIVATE_API_CONFIG_CORRUPTED, file: FILE)
      )
      return false
    end

    # Get the campaign settings
    campaign = get_campaign(@settings_file, campaign_test_key)

    # Validate campaign
    if campaign.nil? || campaign['status'] != STATUS_RUNNING
      # log error
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::CAMPAIGN_NOT_RUNNING, file: FILE, campaign_test_key: campaign_test_key, api: 'track')
      )
      return false
    end

    campaign_id = campaign['id']
    variation_id, variation_name = @decision_service.get_variation_allotted(user_id, campaign)

    if variation_name
      goal = get_campaign_goal(@settings_file, campaign['key'], goal_identifier)

      if goal.nil?
        @logger.log(
          LogLevelEnum::ERROR,
          format(
            LogMessageEnum::ErrorMessages::TRACK_API_GOAL_NOT_FOUND,
            file: FILE, goal_identifier: goal_identifier,
            user_id: user_id,
            campaign_test_key: campaign_test_key
          )
        )
        return false
      elsif goal['type'] == GOALTYPES::REVENUE && !valid_value?(revenue_value)
        @logger.log(
          LogLevelEnum::ERROR,
          format(
            LogMessageEnum::ErrorMessages::TRACK_API_REVENUE_NOT_PASSED_FOR_REVENUE_GOAL,
            file: FILE,
            user_id: user_id,
            goal_identifier: goal_identifier,
            campaign_test_key: campaign_test_key
          )
        )
        return false
      end

      revenue_value = nil if goal['type'] == GOALTYPES::CUSTOM

      properties = build_event(
        @settings_file,
        campaign_id,
        variation_id,
        user_id,
        goal['id'],
        revenue_value
      )
      @event_dispatcher.dispatch(properties)
      return true
    end
    false
  end
end
