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

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../helpers/actions_test_helper'
require_relative '../../../../lib/armagh/standard_actions/collectors/ftp_collect'

class TestFTPCollect < Test::Unit::TestCase
  include ActionsTestHelper
  
  def setup  
    
    @config_values = {
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_out', Armagh::Documents::DocState::READY )},
      
      'collect' => { 'schedule' => '0 * * * *', 'archive' => false},
      
      'ftp' => {
        'host' => 'test_host',
        'username' => 'test_user',
        'password' => Configh::DataTypes::EncodedString.from_plain_text( 'test_pw' ),
        'directory_path' => 'test_dir'
      }
    }
    @ftp = mock('ftp')
#    @ftp.expects( 'write_and_delete_test_file' ).at_least_once 
    Armagh::Support::FTP::Connection.stubs(:open).yields(@ftp)
    @config = Armagh::StandardActions::FTPCollect.create_configuration( [], 'test', @config_values )
    @ftp_collect_action = instantiate_action(Armagh::StandardActions::FTPCollect, @config )
  end
  

  def test_collect
    expected_content = 'test_filename'
    expected_meta = {}
    expected_source = Armagh::Documents::Source.new(
        filename: 'test_filename',
        host: 'test_host',
        path: 'test_dir',
        type: 'file',
        mtime: nil
    )


    @ftp.expects(:get_files).yields('test_filename', {}, nil)

    assert_create(@ftp_collect_action) do |document_id, title, copyright, document_timestamp, content, meta, docspec_name, source|
      assert_equal expected_content, content
      meta.delete('collected_timestamp')
      assert_equal expected_meta, meta
      assert_equal expected_source, source
    end
    
    @ftp_collect_action.expects(:log_info).with( "Collected 1; Failed collecting 0")

    @ftp_collect_action.collect
  end

  def test_collect_one_bad_file
    expected_content = 'test_filename'
    expected_meta = {}
    expected_source = Armagh::Documents::Source.new(
        filename: 'test_filename',
        host: 'test_host',
        path: 'test_dir',
        type: 'file',
        mtime: nil
    )


    @ftp.expects(:get_files).yields(nil, nil, 'oops')
    assert_notify_ops(@ftp_collect_action) do |e|
      assert_equal 'oops', e
    end
    @ftp_collect_action.expects(:log_info).with( "Collected 0; Failed collecting 1")
    @ftp_collect_action.collect
  end

  def test_collect_error
    exception = Armagh::Support::FTP::ConnectionError.new('connection error')
    Armagh::Support::FTP::Connection.stubs(:open).raises(exception)
    assert_notify_ops(@ftp_collect_action) do |e|
      assert_equal exception, e
    end
    @ftp_collect_action.collect
  end

end