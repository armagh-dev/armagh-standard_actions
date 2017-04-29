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

require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

# DO NOT MODIFY THIS FILE

PREFIX = ENV['ARMAGH_TAC_DOC_PREFIX']
ENV['ARMAGH_TAC_DOC_PREFIX'] = 'test_prefix'

require_relative '../../../lib/armagh/standard_actions'

class TestStandardActions < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def self.shutdown
    ENV['ARMAGH_TAC_DOC_PREFIX'] = PREFIX
  end

  def test_name
    assert_not_empty(Armagh::StandardActions::NAME, 'No NAME defined for StandardActions')
  end

  def test_version
    assert_not_empty(Armagh::StandardActions::VERSION, 'No VERSION defined for StandardActions')
  end

end
