# frozen_string_literal: true

class VWO
  module Common
    module CONSTANTS
      API_VERSION = 2
      PLATFORM = 'server'
      SEED_VALUE = 1
      MAX_TRAFFIC_PERCENT = 100
      MAX_TRAFFIC_VALUE = 10_000
      STATUS_RUNNING = 'RUNNING'
      LIBRARY_PATH =  File.expand_path('../..', __dir__)
      HTTP_PROTOCOL = 'http://'
      HTTPS_PROTOCOL = 'https://'
      URL_NAMESPACE = '6ba7b811-9dad-11d1-80b4-00c04fd430c8'
      SDK_VERSION = '1.0.0'

      module ENDPOINTS
        BASE_URL = 'dev.visualwebsiteoptimizer.com'
        ACCOUNT_SETTINGS = '/server-side/settings'
        TRACK_USER = '/server-side/track-user'
        TRACK_GOAL = '/server-side/track-goal'
      end

      module EVENTS
        TRACK_USER = 'track-user'
        TRACK_GOAL = 'track-goal'
      end

      module DATATYPE
        NUMBER = 'number'
        STRING = 'string'
        FUNCTION = 'function'
        BOOLEAN = 'boolean'
      end

      module APIMETHODS
        CREATE_INSTANCE = 'CREATE_INSTANCE'
        ACTIVATE = 'ACTIVATE'
        GET_VARIATION = 'GET_VARIATION'
        TRACK = 'TRACK'
      end

      module GOALTYPES
        REVENUE = 'REVENUE_TRACKING'
        CUSTOM = 'CUSTOM_GOAL'
      end
    end
  end
end
