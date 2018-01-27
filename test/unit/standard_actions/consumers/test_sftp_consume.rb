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

require_relative '../../../helpers/coverage_helper'
require_relative '../../../helpers/actions_test_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'

require 'json'

require_relative '../../../../lib/armagh/standard_actions/consumers/sftp_consume'

class TestSFTPConsume < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @config_values = {
        'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_in', Armagh::Documents::DocState::PUBLISHED )},
      'sftp' => {
        'host' => 'test.url',
        'directory_path' => 'test_dir',
        'username' => 'username',
        'password' => Configh::DataTypes::EncodedString.from_plain_text('password')
      }
    }

    @sftp = mock('sftp')
    Armagh::Support::SFTP::Connection.stubs(:open).yields(@sftp)
    Armagh::Support::SFTP.stubs(:test_connection)
    @config = Armagh::StandardActions::SFTPConsume.create_configuration( [], 'test', @config_values )
    @sftp_consume_action = instantiate_action(Armagh::StandardActions::SFTPConsume, @config )
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def create_doc
    Armagh::Documents::ActionDocument.new(document_id: 'document_id',
                                          title: 'Title',
                                          copyright: 'copyright',
                                          content: {'content' => true},
                                          raw: nil,
                                          metadata: {'metadata' => false},
                                          docspec: Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY),
                                          source: {},
                                          document_timestamp: Time.new(2000,1,1,0,0,0,0).utc)
  end

  def test_consume
    @sftp.expects(:put_files).yields('document_id', nil)

    doc = create_doc

    file_exists = false
    file_content = nil

    FakeFS do
      @sftp_consume_action.consume(doc)
      file_exists = File.file?('DocType-document_id')
      file_content = File.read('DocType-document_id') if file_exists
    end

    assert_true file_exists
    doc.metadata.delete('sftp_consume')
    assert_equal(doc.to_json, file_content)
  end

  def test_consume_defined_filename
    @sftp.expects(:put_files).yields('document_id', nil)

    doc = create_doc

    doc.stubs(document_id: 'document_id!/something')
    doc.metadata['filename'] = 'File/name'

    file_exists = false
    file_content = nil
    FakeFS do
      @sftp_consume_action.consume(doc)
      file_exists = File.file?('File_name')
      file_content = File.read('File_name') if file_exists
    end

    assert_true file_exists
    doc.metadata.delete('sftp_consume')
    assert_equal(doc.to_json, file_content)
  end

  def test_consume_file_sftp_error
    doc = create_doc

    exception = Armagh::Support::SFTP::FileError.new('error')
    @sftp.expects(:put_files).yields('document_id', exception)
    assert_notify_ops(@sftp_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS{@sftp_consume_action.consume(doc)}
  end

  def test_consume_file_unknown_error
    doc = create_doc

    exception = RuntimeError.new('error')
    @sftp.expects(:put_files).yields('document_id', exception)
    assert_notify_dev(@sftp_consume_action) do |e|
      assert_equal exception, e
    end

    FakeFS{@sftp_consume_action.consume(doc)}
  end

  def test_consume_connection_type_error
    doc = create_doc

    exception = Armagh::Support::SFTP::ConnectionError.new('connection error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)

    assert_notify_ops(@sftp_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS{@sftp_consume_action.consume(doc)}
  end

  def test_consume_unknown_error
    doc = create_doc
    exception = RuntimeError.new('error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)
    assert_raise(exception)do
      FakeFS{@sftp_consume_action.consume(doc)}
    end
  end
end
