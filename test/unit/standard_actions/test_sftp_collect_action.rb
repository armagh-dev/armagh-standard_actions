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
require_relative '../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/standard_actions/sftp_collect_action'

class TestSFTPCollectAction < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @config_values = {
      'output' => {
        'docspec' => Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)
      },
      'collect' => {
        'schedule' => '0 * * * *',
        'archive' => false
      },
      'sftp' => {
        'host' => 'test.url',
        'directory_path' => 'test_dir',
        'username' => 'username',
        'password' => Configh::DataTypes::EncodedString.from_plain_text('password')
      }
    }

    @sftp = mock('sftp')
    Armagh::Support::SFTP::Connection.stubs(:open).yields(@sftp)
    @config = Armagh::StandardActions::SFTPCollectAction.create_configuration( [], 'test', @config_values )
    @sftp_collect_action = instantiate_action(Armagh::StandardActions::SFTPCollectAction, @config )
  end

  def test_collect
    expected_content = 'test_filename'
    expected_meta = {}
    expected_source = Armagh::Documents::Source.new(filename: 'test_filename', host: 'test.url', path: 'test_dir', type: 'file', mtime: Time.new(2000).utc)

    @sftp.expects(:get_files).yields('test_filename', {'mtime' => Time.new(2000).utc}, nil)
      assert_create(@sftp_collect_action) do |document_id, title, copyright, document_timestamp, content, meta, docspec_name, source|
      assert_equal expected_content, content
      meta.delete('collected_timestamp')
      assert_equal expected_meta, meta
      assert_equal expected_source, source
    end

    @sftp_collect_action.collect
  end


  def test_collect_file_sftp_error
    exception = Armagh::Support::SFTP::FileError.new('file error')
    @sftp.expects(:get_files).yields('test_filename', {}, exception)
    assert_notify_ops(@sftp_collect_action) do |e|
      assert_equal e, exception
    end

    @sftp_collect_action.collect
  end

  def test_collect_file_unknown_error
    exception = RuntimeError.new('error')
    @sftp.expects(:get_files).yields('test_filename', {}, exception)
    assert_notify_dev(@sftp_collect_action) do |e|
      assert_equal exception, e
    end

    @sftp_collect_action.collect
  end

  def test_collect_connection_type_error
    exception = Armagh::Support::SFTP::ConnectionError.new('connection error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)
    assert_notify_ops(@sftp_collect_action) do |e|
      assert_equal exception, e
    end
    @sftp_collect_action.collect
  end

  def test_collect_unknown_error
    exception = RuntimeError.new('error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)
    assert_raise(exception){@sftp_collect_action.collect}
  end
end
