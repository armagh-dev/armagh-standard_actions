# coding: utf-8
#
# Copyright 2017 Noragh Analytics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'lib/armagh/standard_actions/constants'

def self.get_build_version(version)
  if ENV['ARMAGH_PRODUCTION_RELEASE']
    version
  else
    revision = ENV['ARMAGH_INTEG_BUILD_REVISION']
    if revision.empty?
      "#{version}-dev"
    else
      "#{version}.#{revision}"
    end
  end
rescue
  "#{version}-dev"
end

Gem::Specification.new do |spec|
  spec.name          = 'armagh-standard_actions'
  spec.version       = get_build_version Armagh::StandardActions::VERSION
  spec.authors       = ['Noragh Analytics, Inc']
  spec.email         = []
  spec.summary       = "Armagh standard actions - #{Armagh::StandardActions::NAME}"
  spec.description   = ''
  spec.homepage      = ''
  spec.license       = 'Apache-2.0'

  spec.files         = Dir.glob('lib/**/*') + %w(README.md)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'armagh-base-actions', '< 2.0'
  spec.add_runtime_dependency 'tzinfo', '~> 1.2'

  spec.add_development_dependency 'noragh-gem-tasks', '~> 0.1.3'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 11.0'
  spec.add_development_dependency 'test-unit', '~> 3.1'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'simplecov-rcov', '~> 0.2'
  spec.add_development_dependency 'fakefs', '~> 0.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'webmock', '~> 2.0'
  spec.add_development_dependency 'tzinfo', '~> 1.2'
end
