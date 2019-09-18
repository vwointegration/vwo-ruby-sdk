# frozen_string_literal: true

require 'json'

class VWO
  module Common
    # Schema for verifying the settings_file provided by the customer
    module Schema
      SETTINGS_FILE_SCHEMA = {
        type: 'object',
        properties: {
          version: {
            type: %w[number string]
          },
          accountId: {
            type: %w[number string]
          },
          campaigns: {
            if: {
              type: 'array'
            },
            then: {
              minItems: 1,
              items: {
                '$ref' => '#/definitions/campaign_object_schema'
              }
            },
            else: {
              type: 'object',
              maxProperties: 0
            }
          }
        },
        definitions: {
          campaign_variation_schema: {
            type: 'object',
            properties: {
              id: {
                type: %w[number string]
              },
              name: {
                type: ['string']
              },
              weight: {
                type: %w[number string]
              }
            },
            required: %w[id name weight]
          },
          campaign_object_schema: {
            type: 'object',
            properties: {
              id: {
                type: %w[number string]
              },
              key: {
                type: ['string']
              },
              status: {
                type: ['string']
              },
              percentTraffic: {
                type: ['number']
              },
              variations: {
                type: 'array',
                items: {
                  '$ref' => '#/definitions/campaign_variation_schema'
                }
              },
              minItems: 2
            }
          },
          required: %w[
            id
            key
            status
            percentTraffic
            variations
          ]
        },
        required: %w[
          version
          accountId
          campaigns
        ]
      }.freeze
    end
  end
end
