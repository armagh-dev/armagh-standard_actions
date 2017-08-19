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

require_relative '../../../helpers/coverage_helper'
require_relative '../../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'

require_relative '../../../../lib/armagh/standard_actions/consumers/ofac_consume'

class TestOfacConsume < Test::Unit::TestCase
  include ActionsTestHelper

  def doc_with_content(content)
    Armagh::Documents::ActionDocument.new(
      document_id:        'dd123',
      title:              'Halloween Parade',
      copyright:          '2016 - All Rights Reserved',
      content:            content,
      raw:                nil,
      metadata:           {'meta' => true},
      docspec:            @docspec,
      source:             'chipotle',
      document_timestamp: 1451696523,
      display:            'The school parade was fun'
    )
  end

  def setup
    @tacball_config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_in', Armagh::Documents::DocState::PUBLISHED )},
      'sftp' => {
        'host' => 'test.url',
        'directory_path' => 'test_dir',
        'username' => 'username',
        'password' => Configh::DataTypes::EncodedString.from_plain_text('password')
      },
      'tacball' => {
        'feed' => 'carnitas',
        'source' => 'chipotle'
      }
    }
    @sftp = mock('sftp')
    Armagh::Support::SFTP::Connection.stubs(:open).yields(@sftp)
    Armagh::Support::SFTP.stubs(:test_connection)
    @tacball_config = Armagh::StandardActions::OfacConsume.create_configuration([], 'test', @tacball_config_values)
    @ofac_consume_action = instantiate_action(Armagh::StandardActions::OfacConsume, @tacball_config)
    @ofac_consume_action.stubs(:logger)
    @docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY)

    @fixtures_path = File.join(__dir__, '../../..', 'fixtures')
    @ofac_input_path = File.join(@fixtures_path, "ofac_input")
    @entity_content  = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_entity.yml')))
    @doc = doc_with_content(@entity_content)
    @filename = 'DocType-dd123.tgz.1451696523.160102'
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def test_consume
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @ofac_consume_action.expects(:filename_from_doc).at_least(1).returns(@filename)
    @sftp.expects(:put_file).at_least(0)

    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => @filename
      }
    }

    FakeFS do
      @ofac_consume_action.consume(@doc)
    end

    @doc.metadata['tacball_consume'].delete('timestamp')
    assert_equal expected_metadata, @doc.metadata
  end

  def test_consume_unknown_error
    exception = RuntimeError.new('error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)
    @ofac_consume_action.expects(:notify_dev).at_least(1)

    FakeFS do
      @ofac_consume_action.consume(@doc)
    end
  end

  def test_consume_sftp_error
    exception = Armagh::Support::SFTP::SFTPError.new('error')
    @sftp.expects(:put_file).raises(exception)
    @ofac_consume_action.expects(:filename_from_doc).at_least(1).returns(@filename)
    @ofac_consume_action.expects(:notify_ops).at_least(1)

    FakeFS do
      @ofac_consume_action.consume(@doc)
    end
  end
end
