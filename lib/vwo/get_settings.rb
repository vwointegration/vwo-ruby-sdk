# frozen_string_literal: true

require_relative 'common/utils'
require_relative 'common/constants'
require_relative 'common/requests'
require_relative 'common/validations'

class VWO
  class GetSettings
    include VWO::Common::Validations

    PROTOCOL = 'https'
    HOSTNAME = VWO::Common::CONSTANTS::ENDPOINTS::BASE_URL
    PATH = VWO::Common::CONSTANTS::ENDPOINTS::ACCOUNT_SETTINGS

    def initialize(account_id, sdk_key)
      @account_id = account_id
      @sdk_key = sdk_key
    end

    # Get method to retrieve settings_file for customer from dacdn server
    # @param [string]:      Account ID of user
    # @param [string]:      Unique sdk key for user,
    #                       can be retrieved from our website
    # @return[string]:      Json String representation of settings_file,
    #                       as received from the website,
    #                       nil if no settings_file is found or sdk_key is incorrect

    def get
      is_valid_key = valid_number?(@account_id) || valid_string?(@account_id)

      unless is_valid_key && valid_string?(@sdk_key)
        STDERR.warn 'account_id and sdk_key are required for fetching account settings. Aborting!'
        return '{}'
      end

      dacdn_url = "#{PROTOCOL}://#{HOSTNAME}#{PATH}"

      settings_file_response = VWO::Common::Requests.get(dacdn_url, params)

      if settings_file_response.code != '200'
        STDERR.warn <<-DOC
          Request failed for fetching account settings.
          Got Status Code: #{settings_file_response.code}
          and message: #{settings_file_response.body}.
        DOC
      end
      settings_file_response.body
    rescue StandardError => e
      STDERR.warn "Error fetching Settings File #{e}"
    end

    private

    def params
      {
        a: @account_id,
        i: @sdk_key,
        r: VWO::Common::Utils.get_random_number,
        platform: 'server',
        'api-version' => 2
      }
    end
  end
end
