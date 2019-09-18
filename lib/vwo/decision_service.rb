# frozen_string_literal: true

require_relative 'custom_logger'
require_relative 'common/enums'
require_relative 'common/campaign_utils'
require_relative 'common/validations'
require_relative 'bucketing_service'

# Class encapsulating all decision related capabilities.
class VWO
  class DecisionService
    include VWO::Common::Enums
    include VWO::Common::CampaignUtils
    include Common::Validations

    # Initializes DecisionService with settings_file, UserProfileService and logger.
    # @param[Hash] -   Settings file of the project.
    # @param[Class] -  Class instance having the capability of
    #                   lookup and save.
    def initialize(settings_file, user_profile_service = nil)
      @logger = CustomLogger.get_instance
      @user_profile_service = user_profile_service
      # Check if user_profile_service provided is valid or not
      @user_profile_service = user_profile_service if valid_utility?(user_profile_service, 'user_profile_service')
      @bucketer = VWO::BucketingService.new
      @settings_file = settings_file
    end

    # Returns variation for the user for required campaign
    # First lookup in the UPS, if user_profile is found,
    # return from there
    # Else, calculates the variation with helper method
    #
    #
    # @param[String]          :user_id             The unique ID assigned to User
    # @param[Hash]            :campaign            Campaign in which user is participating
    # @param[String]          :campaign_test_key   The unique ID of the campaign passed
    # @return[String,String]                       ({variation_id, variation_name}|Nil): Tuple of
    #                                              variation_id and variation_name if variation allotted, else nil

    def get(user_id, campaign, campaign_test_key)
      campaign_bucket_map = resolve_campaign_bucket_map(user_id)
      variation = get_stored_variation(user_id, campaign_test_key, campaign_bucket_map) if valid_hash?(campaign_bucket_map)

      if variation
        @logger.log(
          LogLevelEnum::INFO,
          format(
            LogMessageEnum::InfoMessages::GOT_STORED_VARIATION,
            file: FILE,
            campaign_test_key: campaign_test_key,
            user_id: user_id,
            variation_name: variation['name']
          )
        )
        return variation['id'], variation['name']
      end

      variation_id, variation_name = get_variation_allotted(user_id, campaign)

      if variation_name
        save_user_profile(user_id, campaign_test_key, variation_name) if variation_name

        @logger.log(
          LogLevelEnum::INFO,
          format(
            LogMessageEnum::InfoMessages::VARIATION_ALLOCATED,
            file: FILE,
            campaign_test_key: campaign_test_key,
            user_id: user_id,
            variation_name: variation_name
          )
        )
      else
        @logger.log(
          LogLevelEnum::INFO,
          format(LogMessageEnum::InfoMessages::NO_VARIATION_ALLOCATED, file: FILE, campaign_test_key: campaign_test_key, user_id: user_id)
        )
      end
      [variation_id, variation_name]
    end

    # Returns the Variation Allotted to User
    #
    # @param[String]  :user_id      The unique ID assigned to User
    # @param[Hash]    :campaign     Campaign Object
    #
    # @return[Hash]   Variation     Object allotted to User

    def get_variation_allotted(user_id, campaign)
      variation_id, variation_name = nil
      unless valid_value?(user_id)
        @logger.log(
          LogLevelEnum::ERROR,
          format(LogMessageEnum::ErrorMessages::INVALID_USER_ID, file: FILE, user_id: user_id, method: 'get_variation_alloted')
        )
        return variation_id, variation_name
      end

      if @bucketer.user_part_of_campaign?(user_id, campaign)
        variation_id, variation_name = get_variation_of_campaign_for_user(user_id, campaign)
        @logger.log(
          LogLevelEnum::DEBUG,
          format(
            LogMessageEnum::DebugMessages::GOT_VARIATION_FOR_USER,
            file: FILE,
            variation_name: variation_name,
            user_id: user_id,
            campaign_test_key: campaign['key'],
            method: 'get_variation_allotted'
          )
        )
      else
        # not part of campaign
        @logger.log(
          LogLevelEnum::DEBUG,
          format(
            LogMessageEnum::DebugMessages::USER_NOT_PART_OF_CAMPAIGN,
            file: FILE,
            user_id: user_id,
            campaign_test_key: nil,
            method: 'get_variation_allotted'
          )
        )
      end
      [variation_id, variation_name]
    end

    # Assigns random variation ID to a particular user
    # Depending on the PercentTraffic.
    # Makes user a part of campaign if user's included in Traffic.
    #
    # @param[String]              :user_id      The unique ID assigned to a user
    # @param[Hash]                :campaign     The Campaign of which user is to be made a part of
    # @return[Hash|nil]                         Variation allotted to User
    def get_variation_of_campaign_for_user(user_id, campaign)
      unless campaign
        @logger.log(
          LogLevelEnum::ERROR,
          format(
            LogMessageEnum::ErrorMessages::INVALID_CAMPAIGN,
            file: FILE,
            method: 'get_variation_of_campaign_for_user'
          )
        )
        return nil, nil
      end

      variation = @bucketer.bucket_user_to_variation(user_id, campaign)

      if variation && variation['name']
        @logger.log(
          LogLevelEnum::INFO,
          format(
            LogMessageEnum::InfoMessages::GOT_VARIATION_FOR_USER,
            file: FILE,
            variation_name: variation['name'],
            user_id: user_id,
            campaign_test_key: campaign['key']
          )
        )
        return variation['id'], variation['name']
      end

      @logger.log(
        LogLevelEnum::INFO,
        format(
          LogMessageEnum::InfoMessages::USER_GOT_NO_VARIATION,
          file: FILE,
          user_id: user_id,
          campaign_test_key: campaign['key']
        )
      )
      [nil, nil]
    end

    private

    # Returns the campaign bucket map corresponding to the user_id
    #
    # @param[String] :user_id Unique user identifier
    # @return[Hash]

    def resolve_campaign_bucket_map(user_id)
      user_data = get_user_profile(user_id)
      campaign_bucket_map = {}
      campaign_bucket_map = user_data['campaignBucketMap'] if user_data
      campaign_bucket_map.dup
    end

    # Get the UserProfileData after looking up into lookup method
    # Being provided via UserProfileService
    #
    # @param[String]: Unique user identifier
    # @return[Hash|Boolean]: user_profile data

    def get_user_profile(user_id)
      unless @user_profile_service
        @logger.log(
          LogLevelEnum::DEBUG,
          format(LogMessageEnum::DebugMessages::NO_USER_PROFILE_SERVICE_LOOKUP, file: FILE)
        )
        return false
      end

      data = @user_profile_service.lookup(user_id)
      @logger.log(
        LogLevelEnum::INFO,
        format(
          LogMessageEnum::InfoMessages::LOOKING_UP_USER_PROFILE_SERVICE,
          file: FILE,
          user_id: user_id,
          status: data.nil? ? 'Not Found' : 'Found'
        )
      )
      data
    rescue StandardError
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::LOOK_UP_USER_PROFILE_SERVICE_FAILED, file: FILE, user_id: user_id)
      )
      false
    end

    # If userProfileService is provided and variation was stored,
    # Get the stored variation
    # @param[String]            :user_id
    # @param[String]            :campaign_test_key campaign identified
    # @param[Hash]              :campaign_bucket_map BucketMap consisting of stored user variation
    #
    # @return[Object, nil]      if found then variation settings object otherwise None

    def get_stored_variation(user_id, campaign_test_key, campaign_bucket_map)
      if campaign_bucket_map[campaign_test_key]
        decision = campaign_bucket_map[campaign_test_key]
        variation_name = decision['variationName']
        @logger.log(
          LogLevelEnum::DEBUG,
          format(
            LogMessageEnum::DebugMessages::GETTING_STORED_VARIATION,
            file: FILE,
            campaign_test_key: campaign_test_key,
            user_id: user_id,
            variation_name: variation_name
          )
        )
        return get_campaign_variation(
          @settings_file,
          campaign_test_key,
          variation_name
        )
      end

      @logger.log(
        LogLevelEnum::DEBUG,
        format(
          LogMessageEnum::DebugMessages::NO_STORED_VARIATION,
          file: FILE,
          campaign_test_key: campaign_test_key,
          user_id: user_id
        )
      )
      nil
    end

    # If userProfileService is provided and variation was stored
    # Save the assigned variation
    # It creates bucket and then stores.
    #
    # @param[String]              :user_id            Unique user identifier
    # @param[String]              :campaign_test_key  Unique campaign identifier
    # @param[String]              :variation_name     Variation identifier
    # @return[Boolean]                                true if found otherwise false

    def save_user_profile(user_id, _campaign_test_key, variation_name)
      unless @user_profile_service
        @logger.log(
          LogLevelEnum::DEBUG,
          format(LogMessageEnum::DebugMessages::NO_USER_PROFILE_SERVICE_SAVE, file: FILE)
        )
        return false
      end
      new_campaign_bucket_map = {
        campaign_test_key: {
          variationName: variation_name
        }
      }
      @user_profile_service.save(
        userId: user_id,
        campaignBucketMap: new_campaign_bucket_map
      )
      @logger.log(
        LogLevelEnum::INFO,
        format(LogMessageEnum::InfoMessages::SAVING_DATA_USER_PROFILE_SERVICE, file: FILE, user_id: user_id)
      )
      true
    rescue StandardError
      @logger.log(
        LogLevelEnum::ERROR,
        format(LogMessageEnum::ErrorMessages::SAVE_USER_PROFILE_SERVICE_FAILED, file: FILE, user_id: user_id)
      )
      false
    end
  end
end
