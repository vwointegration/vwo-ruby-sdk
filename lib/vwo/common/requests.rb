# frozen_string_literal: true

require 'net/http'

class VWO
  module Common
    class Requests
      def self.get(url, params)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        uri.query = URI.encode_www_form(params)
        Net::HTTP.get_response(uri)
      end
    end
  end
end
