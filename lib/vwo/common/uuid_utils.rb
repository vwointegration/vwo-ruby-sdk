# frozen_string_literal: true

require 'digest'
require_relative '../custom_logger'
require_relative 'enums'
require_relative 'constants'

# Utility module for manipulating VWO campaigns
class VWO
  module Common
    module UUIDUtils
      include VWO::Common::Enums
      include VWO::Common::CONSTANTS

      def self.parse(obj)
        str = obj.to_s.sub(/\Aurn:uuid:/, '')
        str.gsub!(/[^0-9A-Fa-f]/, '')
        [str[0..31]].pack 'H*'
      end

      def self.uuid_v5(uuid_namespace, name)
        uuid_namespace = parse(uuid_namespace)
        hash_class = ::Digest::SHA1
        version = 5

        hash = hash_class.new
        hash.update(uuid_namespace)
        hash.update(name)

        ary = hash.digest.unpack('NnnnnN')
        ary[2] = (ary[2] & 0x0FFF) | (version << 12)
        ary[3] = (ary[3] & 0x3FFF) | 0x8000
        # rubocop:disable Lint/FormatString
        '%08x-%04x-%04x-%04x-%04x%08x' % ary
        # rubocop:enable Lint/FormatString
      end

      VWO_NAMESPACE = uuid_v5(URL_NAMESPACE, 'https://vwo.com')

      # Generates desired UUID
      #
      # @param[Integer|String]      :user_id        User identifier
      # @param[Integer|String]      :account_id     Account identifier
      #
      # @return[Integer]                            Desired UUID
      #
      def generator_for(user_id, account_id)
        user_id = user_id.to_s
        account_id = account_id.to_s
        user_id_namespace = generate(VWO_NAMESPACE, account_id)
        uuid_for_account_user_id = generate(user_id_namespace, user_id)

        desired_uuid = uuid_for_account_user_id.delete('-').upcase

        VWO::CustomLogger.get_instance.log(
          LogLevelEnum::DEBUG,
          format(
            LogMessageEnum::DebugMessages::UUID_FOR_USER,
            file: FileNameEnum::UuidUtil,
            user_id: user_id,
            account_id: account_id,
            desired_uuid: desired_uuid
          )
        )
        desired_uuid
      end

      # Generated uuid from namespace and name, uses uuid5
      #
      # @param[String]        :namespace    Namespace
      # @param[String)        :name         Name
      #
      # @return[String|Nil]                Uuid, nil if any of the arguments is empty
      def generate(namespace, name)
        VWO::Common::UUIDUtils.uuid_v5(namespace, name) if name && namespace
      end
    end
  end
end
