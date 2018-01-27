# Copyright 2018 Noragh Analytics, Inc.
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

require 'test/unit'
require 'fakefs/safe'
require 'mocha/test_unit'

require_relative '../helpers/actions_test_helper'
require_relative '../../lib/armagh/standard_actions/consumers/tacball_consume'

class TestIntegrationTacballConsume < Test::Unit::TestCase

  include ActionsTestHelper

  READ_WRITE_DIR = 'readwrite_dir/tacballs'
  DUP_PATHS      = [ 'readwrite_dir/tacdup' ]

  def setup
    local_integration_test_config = load_local_integration_test_config
    @host = local_integration_test_config['test_sftp_host']
    @username = local_integration_test_config['test_sftp_username']
    @password = local_integration_test_config['test_sftp_password']
    @port = local_integration_test_config['test_sftp_port']
    @directory_path = READ_WRITE_DIR
    @duplicate_put_directory_paths = DUP_PATHS

    @sftp_config_values = {
      'host' => @host,
      'username' => @username,
      'password' => @password,
      'directory_path' => @directory_path,
      'duplicate_put_directory_paths' => @duplicate_put_directory_paths,
      'port' => @port
    }

    @config_values = {
        'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_in', Armagh::Documents::DocState::PUBLISHED )},
      'sftp' => @sftp_config_values,
      'tacball' => {
        'feed' => 'carnitas',
        'source' => 'chipotle'
      }
    }

    @config_store = []

    @config = Armagh::StandardActions::TacballConsume.create_configuration([], 'test', @config_values)
    @tacball_consume_action = instantiate_action(Armagh::StandardActions::TacballConsume, @config)
    @tacball_consume_action.stubs(:logger).once
    docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::PUBLISHED)
    docsource = Armagh::Documents::Source.new(type: 'file', filename: 'orig-source-file')
    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        'dd123',
      title:              'Halloween Parade',
      copyright:          '2016 - All Rights Reserved',
      content:            {'content' => true},
      raw:                'raw content',
      metadata:           {'meta' => true},
      docspec:            docspec,
      source:             docsource,
      document_timestamp: 1451696523,
      display:            'The school parade was fun'
    )
    @doc.text = 'This is a text file'
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def load_local_integration_test_config
    config = nil
    config_filepath = File.join(__dir__, 'local_integration_test_config.json')

    begin
      config = JSON.load(File.read(config_filepath))
      errors = []
      if config.is_a? Hash
        %w(test_sftp_username test_sftp_password test_sftp_host test_sftp_port).each do |k|
          errors << "Config file missing member #{k}" unless config.has_key?(k)
        end
      else
        errors << 'Config file should contain a hash of test_sftp_username, test_sftp_password (Base64 encoded), test_sftp_host, and test_sftp_port'
      end

      if errors.empty?
        config['test_sftp_password'] = Configh::DataTypes::EncodedString.from_encoded(config['test_sftp_password'])
      else
        raise errors.join("\n")
      end
    rescue => e
      puts "Integration test environment not set up.  See test/integration/ftp_test.readme.  Detail: #{ e.message }"
      pend
    end
    config
  end

  def test_consume
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    config = Armagh::Support::SFTP.create_configuration(@config_store, 'consume', {'sftp' => @sftp_config_values})
    FakeFS {
      @tacball_consume_action.consume(@doc)
    }

    [ READ_WRITE_DIR, *DUP_PATHS ].each do |target_dir|
      sftp_path = File.join( target_dir, @config_values['tacball']['feed'] )
      Armagh::Support::SFTP::Connection.open(config) do |sftp|
        assert_equal ['DocType-dd123.tgz.1451696523.160102'], sftp.ls(sftp_path)
        sftp.remove(sftp_path)
      end
    end
  end

end
