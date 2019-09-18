# frozen_string_literal: true

require_relative 'custom_logger'
require_relative 'common/enums'
require_relative 'common/campaign_utils'

# Representation of the VWO settings file.

class VWO
  class ProjectConfigManager
    include VWO::Common::Enums
    include VWO::Common::CampaignUtils

    # ProjectConfigManager init method to load and set project config data.
    #
    # @params
    #  settings_file (Hash): Hash object of setting
    #  representing the project settings_file.

    def initialize(settings_file)
      @settings_file = JSON.parse(settings_file)
      @logger = VWO::CustomLogger.get_instance
    end

    # Processes the settings_file, assigns variation allocation range
    def process_settings_file
      (@settings_file['campaigns'] || []).each do |campaign|
        set_variation_allocation(campaign)
      end
      @logger.log(
        LogLevelEnum::DEBUG,
        format(LogMessageEnum::DebugMessages::SETTINGS_FILE_PROCESSED, file: FileNameEnum::ProjectConfigManager)
      )
    end

    def get_settings_file
      @settings_file
    end
  end
end
