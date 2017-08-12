# Copyright 2016 Noragh Analytics, Inc.
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

require_relative '../../../../lib/armagh/standard_actions/consumers/ftp_consume'

class TestFTPConsume < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dans_in', Armagh::Documents::DocState::PUBLISHED )},
      'ftp' => {
        'host' => 'test.url',
        'directory_path' => 'test_dir',
        'username' => 'username',
        'password' => Configh::DataTypes::EncodedString.from_plain_text('password')
      }
    }

    @ftp = mock('ftp')
    @ftp.expects( 'write_and_delete_test_file' ).at_least_once
    Armagh::Support::FTP::Connection.stubs(:open).yields(@ftp)
    @config = Armagh::StandardActions::FTPConsume.create_configuration( [], 'test', @config_values )
    @ftp_consume_action = instantiate_action(Armagh::StandardActions::FTPConsume, @config )
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def mock_doc
    doc = mock('doc')
    doc.stubs(document_id: 'document_id')
    doc.stubs(content: {'document_content' => 'details'})
    doc.stubs(metadata: {'meta' => true})
    docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY)
    doc.stubs(docspec: docspec)
    doc
  end

  def test_consume
    expected_content = {'document_content' => 'details'}
    expected_meta = {
        'meta' => true,
        'ftp_consume' => {
            'host' => 'test.url',
            'path' => 'test_dir',
            'filename' => 'document_id'
        }
    }
    @ftp.expects(:put_files).yields('document_id', nil)

    doc = mock_doc

    doc.stubs(document_id: 'document_id!/something')

    file_exists = false
    file_content = nil
    FakeFS do
      @ftp_consume_action.consume(doc)
      file_exists = File.file?('DocType-document_id__something')
      file_content = File.read('DocType-document_id__something') if file_exists
    end

    doc.metadata['ftp_consume'].delete('timestamp')
    assert_equal(doc.metadata, expected_meta)

    assert_true file_exists
    assert_equal(expected_content.to_json, file_content)
  end

  def test_consume_whole_document
    @config_values['ftp']['transfer_doc_json'] = true
    @config = Armagh::StandardActions::FTPConsume.create_configuration( [], 'test1', @config_values )
    @ftp_consume_action = instantiate_action(Armagh::StandardActions::FTPConsume, @config)

    @ftp.expects(:put_files).yields('document_id', nil)

    doc = Armagh::Documents::ActionDocument.new(document_id: 'document_id',
                                                title: 'Title',
                                                copyright: 'copyright',
                                                content: {'content' => true},
                                                raw: nil,
                                                metadata: {'metadata' => false},
                                                docspec: Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY),
                                                source: {},
                                                document_timestamp: Time.new(2000,1,1,0,0,0,0).utc)

    file_exists = false
    file_content = nil

    FakeFS do
      @ftp_consume_action.consume(doc)
      file_exists = File.file?('DocType-document_id')
      file_content = File.read('DocType-document_id') if file_exists
    end

    assert_true file_exists
    doc.metadata.delete('ftp_consume')
    assert_equal(doc.to_json, file_content)
  end

  def test_consume_defined_filename
    expected_content = {'document_content' => 'details'}
    expected_meta = {
        'meta' => true,
        'filename' => 'File/name',
        'ftp_consume' => {
            'host' => 'test.url',
            'path' => 'test_dir',
            'filename' => 'document_id'
        }
    }

    @ftp.expects(:put_files).yields('document_id', nil)

    doc = mock_doc

    doc.stubs(document_id: 'document_id!/something')
    doc.metadata['filename'] = 'File/name'

    file_exists = false
    file_content = nil
    FakeFS do
      @ftp_consume_action.consume(doc)
      file_exists = File.file?('File_name')
      file_content = File.read('File_name') if file_exists
    end

    doc.metadata['ftp_consume'].delete('timestamp')
    assert_equal(doc.metadata, expected_meta)

    assert_true file_exists
    assert_equal(expected_content.to_json, file_content)
  end

  def test_consume_file_unknown_error
    doc = mock_doc

    exception = RuntimeError.new('error')
    @ftp.expects(:put_files).yields('document_id', exception)
    assert_notify_dev(@ftp_consume_action) do |e|
      assert_equal exception, e
    end

    FakeFS{@ftp_consume_action.consume(doc)}
  end

  def test_consume_connection_type_error
    doc = mock_doc

    exception = Armagh::Support::FTP::ConnectionError.new('connection error')
    Armagh::Support::FTP::Connection.stubs(:open).raises(exception)

    assert_notify_ops(@ftp_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS{@ftp_consume_action.consume(doc)}
  end

  def test_consume_unhandled_error
    doc = mock_doc
    exception = Armagh::Support::FTP::UnhandledError.new('error')
    Armagh::Support::FTP::Connection.stubs(:open).raises(exception)

    assert_notify_ops(@ftp_consume_action) do |e|
      assert_equal exception, e
    end

    FakeFS{@ftp_consume_action.consume(doc)}
  end
end
