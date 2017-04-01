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

@tac_doc_prefix = ENV['ARMAGH_TAC_DOC_PREFIX']
ENV['ARMAGH_TAC_DOC_PREFIX'] = 'test_prefix'

require_relative '../../helpers/coverage_helper'
require_relative '../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'

require_relative '../../../lib/armagh/standard_actions/tacball_consume_action'

class TacballConsumeActionTest < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @config_values = {
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
    @config = Armagh::StandardActions::TacballConsumeAction.create_configuration([], 'test', @config_values)
    @tacball_consume_action = instantiate_action(Armagh::StandardActions::TacballConsumeAction, @config)
    @tacball_consume_action.stubs(:logger)
    docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY)
    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        'dd123',
      title:              'Halloween Parade',
      copyright:          '2016 - All Rights Reserved',
      content:            {'content' => true},
      metadata:           {'meta' => true},
      docspec:            docspec,
      source:             'chipotle',
      document_timestamp: 1451696523,
      display:            'The school parade was fun'
    )
    @doc.text = 'This is a text file'
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def self.shutdown
    ENV['ARMAGH_TAC_DOC_PREFIX'] = @tac_doc_prefix
  end

  def test_invalid_tac_doc_prefix_raises_error
    @tacball_consume_action.unstub(:logger)
    ENV['ARMAGH_TAC_DOC_PREFIX'] = nil
    error = assert_raise(Armagh::StandardActions::TacballConsumeAction::TACDocPrefixError) {
      load "#{__dir__}/../../../lib/armagh/standard_actions/tacball_consume_action.rb"
    }
    assert_equal 'The environment variable ARMAGH_TAC_DOC_PREFIX is not set but is required.', error.message
  end

  def test_consume
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => 'DocType-dd123.tgz.1451696523.160102'
      }
    }
    @sftp.expects(:put_file).at_least(0)
    file_exists = false
    FakeFS do
      @tacball_consume_action.consume(@doc)
      file_exists = File.file?('DocType-dd123.tgz.1451696523.160102')
    end
    assert_true file_exists
    @doc.metadata['tacball_consume'].delete('timestamp')
    assert_equal expected_metadata, @doc.metadata
  end

  def test_consume_with_type_specified
    @config_values['tacball']['type'] = 'DocumentType'
    config = Armagh::StandardActions::TacballConsumeAction.create_configuration([], 'test', @config_values)
    tacball_consume_action = instantiate_action(Armagh::StandardActions::TacballConsumeAction, config)
    tacball_consume_action.stubs(:logger)

    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => 'DocumentType-dd123.tgz.1451696523.160102'
      }
    }
    @sftp.expects(:put_file).at_least(0)
    file_exists = false
    FakeFS do
      tacball_consume_action.consume(@doc)
      file_exists = File.file?('DocumentType-dd123.tgz.1451696523.160102')
    end
    assert_true file_exists
    @doc.metadata['tacball_consume'].delete('timestamp')
    assert_equal expected_metadata, @doc.metadata
  end

  def test_consume_unknown_error
    exception = RuntimeError.new('error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)
    assert_notify_dev(@tacball_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS {
      FileUtils.touch('/DocType.')
      @tacball_consume_action.consume(@doc)
    }
  end

  def test_consume_sftp_error
    exception = Armagh::Support::SFTP::SFTPError.new('error')
    @sftp.expects(:put_file).raises(exception)
    assert_notify_ops(@tacball_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS {
      FileUtils.touch('/DocType.')
      @tacball_consume_action.consume(@doc)
    }
  end
end
