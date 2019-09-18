# frozen_string_literal: true

require 'murmurhash3'
require_relative 'custom_logger'
require_relative 'common/enums'
require_relative 'common/validations'
require_relative 'common/constants'

# Class encapsulating all decision related capabilities.
class VWO
  class BucketingService
    include VWO::Common::Enums
    include VWO::Common::CONSTANTS
    include VWO::Common::Validations

    U_MAX_32_BIT = 0xFFFFFFFF
    MAX_HASH_VALUE = 2**32
    FILE = FileNameEnum::BucketingService

    def initialize
      @logger = CustomLogger.get_instance
    end

    # Calculate if this user should become part of the campaign or not
    # @param[String]         :user_id     The unique ID assigned to a user
    # @param[Dict]           :campaign    For getting traffic allotted to the campaign
    # @return[Boolean]                    If User is a part of Campaign or not
    #
    def user_part_of_campaign?(user_id, campaign)
      unless valid_value?(user_id)
        @logger.log(
          LogLevelEnum::ERROR,
          format(LogMessageEnum::ErrorMessages::INVALID_USER_ID, file: FILE, user_id: user_id, method: 'is_user_part_of_campaign')
        )
        return false
      end

      if campaign.nil?
        @logger.log(
          LogLevelEnum::ERROR,
          format(LogMessageEnum::ErrorMessages::INVALID_CAMPAIGN, file: FILE, method: 'is_user_part_of_campaign')
        )
        return false
      end

      traffic_allocation = campaign['percentTraffic']

      value_assigned_to_user = get_bucket_value_for_user(user_id)
      is_user_part = (value_assigned_to_user != 0) && value_assigned_to_user <= traffic_allocation
      @logger.log(
        LogLevelEnum::INFO,
        format(LogMessageEnum::InfoMessages::USER_ELIGIBILITY_FOR_CAMPAIGN, file: FILE, user_id: user_id, is_user_part: is_user_part)
      )
      is_user_part
    end

    # Validates the User ID and
    # Generates Variation into which the User is bucketed in.
    #
    # @param[String]            :user_id          The unique ID assigned to User
    # @param[Hash]              :campaign         The Campaign of which User is a part of
    #
    # @return[Hash|nil}                           Variation data into which user is bucketed in
    #                                             or nil if not
    def bucket_user_to_variation(user_id, campaign)
      unless valid_value?(user_id)
        @logger.log(
          LogLevelEnum::ERROR,
          format(LogMessageEnum::ErrorMessages::INVALID_USER_ID, file: FILE, user_id: user_id, method: 'bucket_user_to_variation')
        )
        return
      end

      unless campaign
        @logger.log(
          LogLevelEnum::ERROR,
          format(LogMessageEnum::ErrorMessages::INVALID_CAMPAIGN, file: FILE, method: 'is_user_part_of_campaign')
        )
        return
      end

      hash_value = MurmurHash3::V32.str_hash(user_id, SEED_VALUE) & U_MAX_32_BIT
      normalize = MAX_TRAFFIC_VALUE / campaign['percentTraffic']
      multiplier = normalize / 100
      bucket_value = generate_bucket_value(
        hash_value,
        MAX_TRAFFIC_VALUE,
        multiplier
      )

      @logger.log(
        LogLevelEnum::DEBUG,
        format(
          LogMessageEnum::DebugMessages::VARIATION_HASH_BUCKET_VALUE,
          file: FILE,
          user_id: user_id,
          campaign_test_key: campaign['key'],
          percent_traffic: campaign['percentTraffic'],
          bucket_value: bucket_value,
          hash_value: hash_value
        )
      )
      get_variation(campaign, bucket_value)
    end

    private

    # Returns the Variation by checking the Start and End
    # Bucket Allocations of each Variation
    #
    # @param[Hash]        :campaign       Which contains the variations
    # @param[Integer]     :bucket_value   The bucket Value of the user
    # @return[Hash|nil]                   Variation data allotted to the user or None if not
    #
    def get_variation(campaign, bucket_value)
      campaign['variations'].find do |variation|
        (variation['start_variation_allocation']..variation['end_variation_allocation']).cover?(bucket_value)
      end
    end

    # Validates the User ID and generates Bucket Value of the
    # User by hashing the userId by murmurHash and scaling it down.
    #
    # @param[String]    :user_id    The unique ID assigned to User
    # @return[Integer]              The bucket Value allotted to User
    #                               (between 1 to $this->$MAX_TRAFFIC_PERCENT)
    def get_bucket_value_for_user(user_id)
      hash_value = MurmurHash3::V32.str_hash(user_id, SEED_VALUE) & U_MAX_32_BIT
      bucket_value = generate_bucket_value(hash_value, MAX_TRAFFIC_PERCENT)

      @logger.log(
        LogLevelEnum::DEBUG,
        format(
          LogMessageEnum::DebugMessages::USER_HASH_BUCKET_VALUE,
          file: FILE,
          hash_value: hash_value,
          bucket_value: bucket_value,
          user_id: user_id
        )
      )
      bucket_value
    end

    # Generates Bucket Value of the User by hashing the User ID by murmurHash
    # And scaling it down.
    #
    # @param[Integer]             :hash_value   HashValue generated after hashing
    # @param[Integer]             :max_value    The value up-to which hashValue needs to be scaled
    # @param[Integer]             :multiplier
    # @return[Integer]                          Bucket Value of the User
    #
    def generate_bucket_value(hash_value, max_value, multiplier = 1)
      ratio = hash_value.to_f / MAX_HASH_VALUE
      multiplied_value = (max_value * ratio + 1) * multiplier
      multiplied_value.to_i
    end
  end
end
