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

require_relative '../../../../lib/armagh/standard_actions/consumers/movie_tacball_consume'

class TestMovieTacballConsume < Test::Unit::TestCase
  include ActionsTestHelper

  def setup
    @tacball_config_values = {
        'action' => { 'workflow' => 'wf'},
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
    @tacball_config = Armagh::StandardActions::MovieTacballConsume.create_configuration([], 'test', @tacball_config_values)
    @tacball_consume_action = instantiate_action(Armagh::StandardActions::MovieTacballConsume, @tacball_config)
    @tacball_consume_action.stubs(:logger)
    docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY)
    docsource = Armagh::Documents::Source.new(type: 'file', filename: 'orig-source-file')

    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        'dd123',
      title:              'Halloween Parade',
      copyright:          '2016 - All Rights Reserved',
      content:            {'txt_content'  => 'This is movie text',
                           'html_content' => 'This is movie html'},
      raw:                'raw content',
      metadata:           {'meta' => true},
      docspec:            docspec,
      source:             docsource,
      document_timestamp: 1451696523,
      display:            'The school parade was fun'
    )
    @expected_tacball_filename = 'DocType-dd123.tgz.1451696523.160102'
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def test_consume
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => @expected_tacball_filename
      }
    }
    @sftp.expects(:put_file).at_least(0)

    tacball_file_exists = false
    FakeFS do
      @tacball_consume_action.consume(@doc)

      tacball_file_exists = File.file?(@expected_tacball_filename)
    end

    assert_true tacball_file_exists

    @doc.metadata['tacball_consume'].delete('timestamp')
    assert_equal expected_metadata, @doc.metadata
  end

  def test_consume_with_txt_and_html_contents
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => @expected_tacball_filename
      }
    }
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        @tacball_consume_action.consume(@doc)
        assert_true File.file?(@expected_tacball_filename)

        @doc.metadata['tacball_consume'].delete('timestamp')
        assert_equal expected_metadata, @doc.metadata

        tgz_hash = tgz_to_hash(@expected_tacball_filename)
        tgz_hash.each do |fname, contents|
          assert_match /#{@doc.content['txt_content' ]}/, contents  if fname =~ /\.txt$/
          assert_match /#{@doc.content['html_content']}/, contents  if fname =~ /\.html$/
        end
      end
    end
  end

  def test_consume_with_only_html_contents
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => @expected_tacball_filename
      }
    }
    @sftp.expects(:put_file).at_least(0)
    tacball_file_exists = false
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        doc = @doc.dup
        doc.content.delete('txt_content')
        doc.content['html_content'] = '<h1>Header1</h1><div attr_in_div="value_in_div">This is html content</div>'

        expected_txt_contents = 'html_to_text text'
        @tacball_consume_action.stubs(:html_to_text).once.returns(expected_txt_contents)

        @tacball_consume_action.consume(doc)
        assert_true File.file?(@expected_tacball_filename)

        doc.metadata['tacball_consume'].delete('timestamp')
        assert_equal expected_metadata, doc.metadata

        tgz_hash = tgz_to_hash(@expected_tacball_filename)
        html_file_content = nil
        txt_file_content  = nil
        tgz_hash.each do |fname, contents|
          txt_file_content  = contents  if fname =~ /\.txt$/
          html_file_content = contents  if fname =~ /\.html$/
        end

        assert_match /Header1/,                  html_file_content
        assert_match /This is html content/,     html_file_content

        assert_match /#{expected_txt_contents}/, txt_file_content
      end
    end
  end

  def test_consume_with_type_specified
    @expected_tacball_filename.sub!('DocType',  'DocumentType')
    @tacball_config_values['tacball']['type'] = 'DocumentType'
    config = Armagh::StandardActions::MovieTacballConsume.create_configuration([], 'test', @tacball_config_values)
    tacball_consume_action = instantiate_action(Armagh::StandardActions::MovieTacballConsume, config)
    tacball_consume_action.stubs(:logger)

    expected_metadata = {
      'meta' => true,
      'tacball_consume' => {
        'host' => 'test.url',
        'path' => 'test_dir',
        'filename' => @expected_tacball_filename
      }
    }
    @sftp.expects(:put_file).at_least(0)

    tacball_file_exists = false
    FakeFS do
      tacball_consume_action.consume(@doc)

      tacball_file_exists = File.file?(@expected_tacball_filename)
    end

    assert_true tacball_file_exists

    @doc.metadata['tacball_consume'].delete('timestamp')
    assert_equal expected_metadata, @doc.metadata
  end

  def test_consume_unknown_error
    exception = RuntimeError.new('error')
    Armagh::Support::SFTP::Connection.stubs(:open).raises(exception)
    assert_notify_dev(@tacball_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS do
      FileUtils.touch('/DocType.')
      @tacball_consume_action.consume(@doc)
    end
  end

  def test_consume_sftp_error
    exception = Armagh::Support::SFTP::SFTPError.new('error')
    @sftp.expects(:put_file).raises(exception)
    assert_notify_ops(@tacball_consume_action) do |e|
      assert_equal exception, e
    end
    FakeFS do
      FileUtils.touch('/DocType.')
      @tacball_consume_action.consume(@doc)
    end
  end

  def test_consume_no_html_content_error
    assert_notify_dev(@tacball_consume_action) do |e|
      assert_kind_of Armagh::StandardActions::MovieTacballConsume::MovieTacballConsumeError, e
      assert_match   /must have 'html_content'/, e.message()
    end
    FakeFS do
      doc = @doc
      doc.content.delete('html_content')

      FileUtils.touch('/DocType.')
      @tacball_consume_action.consume(@doc)
    end
  end

  def reset_for_attach
    @tacball_config_values['tacball']['attach_orig_file'] = true
    @tacball_config = Armagh::StandardActions::MovieTacballConsume.create_configuration([], 'test', @tacball_config_values)
    @tacball_consume_action = instantiate_action(Armagh::StandardActions::MovieTacballConsume, @tacball_config)
    @tacball_consume_action.stubs(:logger)
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
  end

  def test_consume_attach_orig
    reset_for_attach
    tacball_file_exists = false
    orig_content = nil
    FakeFS do
      @tacball_consume_action.consume(@doc)

      tacball_file_exists = File.file?(@expected_tacball_filename)
      if tacball_file_exists
        tgz_str = StringIO.new(File.read(@expected_tacball_filename))
        tgz = Gem::Package::TarReader.new(Zlib::GzipReader.new(tgz_str))
        tgz.rewind
        tgz.seek(@doc.source.filename) { |entry| orig_content = entry.read }
        tgz.close
      end
    end

    assert_true tacball_file_exists
    assert_equal @doc.raw, orig_content
  end

  def test_consume_attach_orig_no_filename
    reset_for_attach
    @doc.source.filename = nil
    @doc.source.type = 'url'
    tacball_file_exists = false
    orig_content = nil
    FakeFS do
      @tacball_consume_action.consume(@doc)

      tacball_file_exists = File.file?(@expected_tacball_filename)
      if tacball_file_exists
        tgz_str = StringIO.new(File.read(@expected_tacball_filename))
        tgz = Gem::Package::TarReader.new(Zlib::GzipReader.new(tgz_str))
        tgz.rewind
        i = 0
        tgz.each do |entry|
          next if (i += 1) < 4  # fourth file is the original file
          orig_content = entry.read
        end
        tgz.close
      end
    end

    assert_true tacball_file_exists
    assert_equal @doc.raw, orig_content
  end
end
