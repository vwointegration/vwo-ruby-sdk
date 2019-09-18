# frozen_string_literal: true

require_relative 'lib/vwo/common/constants'

Gem::Specification.new do |spec|
  spec.name          = 'vwo-sdk'
  spec.version       = VWO::Common::CONSTANTS::SDK_VERSION
  spec.authors       = ['Sahil Batla', 'VWO']
  spec.email         = ['dev@wingify.com']

  spec.summary       = "Ruby SDK for VWO server-side framework"
  spec.description   = "A Ruby SDK for VWO server-side framework."
  spec.homepage      = 'https://vwo.com/fullstack/server-side-testing/'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rubocop', '0.74.0'
  spec.add_development_dependency 'byebug', '11.0.1'

  spec.add_runtime_dependency 'json-schema', '~> 2.8'
  spec.add_runtime_dependency 'murmurhash3', '~> 0.1'
end
