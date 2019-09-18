# frozen_string_literal: true

require_relative '../custom_logger'
require_relative 'enums'
require_relative 'constants'

# Utility module for manipulating VWO campaigns
class VWO
  module Common
    module CampaignUtils
      include VWO::Common::Enums
      include VWO::Common::CONSTANTS

      # Finds and Returns campaign from given campaign_test_key.
      #
      # @param[Hash]      :settings_file      Settings file for the project
      # @param[String]    :campaign_test_key  Campaign identifier key
      # @return[Hash]     :campaign object

      def get_campaign(settings_file, campaign_test_key)
        (settings_file['campaigns'] || []).find do |campaign|
          campaign['key'] == campaign_test_key
        end
      end

      # Sets variation allocation range in the provided campaign
      #
      # @param [Hash]: Campaign object

      def set_variation_allocation(campaign)
        current_allocation = 0
        campaign['variations'].each do |variation|
          step_factor = get_variation_bucketing_range(variation['weight'])
          if step_factor
            start_range = current_allocation + 1
            end_range = current_allocation + step_factor
            variation['start_variation_allocation'] = start_range
            variation['end_variation_allocation'] = end_range
            current_allocation += step_factor
          else
            variation['start_variation_allocation'] = -1
            variation['end_variation_allocation'] = -1
          end

          CustomLogger.get_instance.log(
            LogLevelEnum::INFO,
            format(
              LogMessageEnum::InfoMessages::VARIATION_RANGE_ALLOCATION,
              file: FileNameEnum::CampaignUtil,
              campaign_test_key: campaign['key'],
              variation_name: variation['name'],
              variation_weight: variation['weight'],
              start: variation['start_variation_allocation'],
              end: variation['end_variation_allocation']
            )
          )
        end
      end

      # Returns goal from given campaign_test_key and gaol_identifier.
      # @param[Hash]              :settings_file        Settings file of the project
      # @param[String]            :campaign_test_key    Campaign identifier key
      # @param[String]            :goal_identifier      Goal identifier
      #
      # @return[Hash]                                   Goal corresponding to Goal_identifier in respective campaign

      def get_campaign_goal(settings_file, campaign_test_key, goal_identifier)
        return unless settings_file && campaign_test_key && goal_identifier

        campaign = get_campaign(settings_file, campaign_test_key)
        return unless campaign

        campaign['goals'].find do |goal|
          goal['identifier'] == goal_identifier
        end
      end

      private

      # Returns the bucket size of variation.
      # @param (Number): weight of variation
      # @return (Integer): Bucket start range of Variation

      def get_variation_bucketing_range(weight)
        return 0 if weight.nil? || weight == 0

        start_range = (weight * 100).ceil.to_i
        [start_range, MAX_TRAFFIC_VALUE].min
      end

      # Returns variation from given campaign_test_key and variation_name.
      #
      # @param[Hash]            :settings_file  Settings file of the project
      # @param[Hash]            :campaign_test_key Campaign identifier key
      # @param[String]          :variation_name Variation identifier
      #
      # @return[Hash]           Variation corresponding to variation_name in respective campaign

      def get_campaign_variation(settings_file, campaign_test_key, variation_name)
        return if settings_file && campaign_test_key && variation_name

        campaign = get_campaign(settings_file, campaign_test_key)
        return unless campaign

        campaign['variations'].find do |variation|
          variation['name'] == variation_name
        end
      end
    end
  end
end
