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

require_relative '../../../../lib/armagh/standard_actions/consumers/tacball_consume'

class TestTacballConsume < Test::Unit::TestCase
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
    @tacball_config = Armagh::StandardActions::TacballConsume.create_configuration([], 'test', @tacball_config_values)
    @tacball_consume_action = instantiate_action(Armagh::StandardActions::TacballConsume, @tacball_config)
    @tacball_consume_action.stubs(:logger)

    @expected_html_template_content = 'expected html_template_content'
    @expected_text_template_content = 'expected text_template_content'
    @expected_doc_display_content   = 'expected doc.display'
    @expected_doc_text_content      = 'expected doc.text'

    docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY)
    docsource = Armagh::Documents::Source.new(type: 'file', filename: 'orig-source-file')

    @doc = Armagh::Documents::ActionDocument.new(
      document_id:        'dd123',
      title:              'Halloween Parade',
      copyright:          '2016 - All Rights Reserved',
      content:            {'some_key' => 'some content'},
      raw:                'raw content',
      metadata:           {'meta' => true},
      docspec:            docspec,
      source:             docsource,
      document_timestamp: 1451696523,
      display:            @expected_doc_display_content
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
    file_exists = false
    FakeFS do
      @tacball_consume_action.consume(@doc)
      file_exists = File.file?(@expected_tacball_filename)
    end
    assert_true file_exists
    @doc.metadata['tacball_consume'].delete('timestamp')
    assert_equal expected_metadata, @doc.metadata
  end

  def test_consume_with_type_specified
    @expected_tacball_filename.sub!('DocType',  'DocumentType')
    @tacball_config_values['tacball']['type'] = 'DocumentType'
    config = Armagh::StandardActions::TacballConsume.create_configuration([], 'test', @tacball_config_values)
    tacball_consume_action = instantiate_action(Armagh::StandardActions::TacballConsume, config)
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
    file_exists = false
    FakeFS do
      tacball_consume_action.consume(@doc)
      file_exists = File.file?(@expected_tacball_filename)
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

  def reset_for_attach
    @tacball_config_values['tacball']['attach_orig_file'] = true
    @tacball_config = Armagh::StandardActions::TacballConsume.create_configuration([], 'test', @tacball_config_values)
    @tacball_consume_action = instantiate_action(Armagh::StandardActions::TacballConsume, @tacball_config)
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

  def test_consume_html_content_precedence_template_above_all_others
    tacball_consume_action_with_template = setup_tacball_consume_action_with_template

    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        tacball_consume_action_with_template.consume(@doc)
        assert_true File.file?(@expected_tacball_filename)

        html_file_content = get_html_file_content(@expected_tacball_filename)

        expected = @expected_html_template_content
        assert_false    expected.to_s.strip.empty?  ## verify I didn't make typo
        assert_match /#{expected}/, html_file_content
      end
    end
  end

  def test_consume_html_content_precedence_no_template_then_display
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        @tacball_consume_action.consume(@doc)
        assert_true File.file?(@expected_tacball_filename)

        html_file_content = get_html_file_content(@expected_tacball_filename)

        expected = @expected_doc_display_content
        assert_false    expected.to_s.strip.empty?  ## verify I didn't make typo
        assert_match /#{expected}/, html_file_content
      end
    end
  end

  def test_consume_html_content_precedence_no_display
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        ## doc.text ==> html will have doc.text
        doc = @doc.dup
        doc.text    = @expected_doc_text_content
        doc.display = nil

        @tacball_consume_action.consume(doc)
        assert_true File.file?(@expected_tacball_filename)

        html_file_content = get_html_file_content(@expected_tacball_filename)

        expected = @expected_doc_text_content
        assert_false    expected.to_s.strip.empty?  ## verify I didn't make typo
        assert_match /#{expected}/, html_file_content

        ## no anything ==> html will not have any expected content
        doc = @doc.dup
        doc.text    = ''
        doc.display = nil

        @tacball_consume_action.consume(doc)
        assert_true File.file?(@expected_tacball_filename)

        html_file_content = get_html_file_content(@expected_tacball_filename)

        assert_not_match /#{@expected_html_template_content}/, html_file_content
        assert_not_match /#{@expected_text_template_content}/, html_file_content
        assert_not_match /#{@expected_doc_display_content  }/, html_file_content
        assert_not_match /#{@expected_doc_text_content     }/, html_file_content
      end
    end
  end

  def test_consume_txt_content_precedence_above_all_others
    tacball_consume_action_with_template = setup_tacball_consume_action_with_template

    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        doc = @doc.dup
        doc.text = @expected_doc_text_content

        tacball_consume_action_with_template.consume(doc)
        assert_true File.file?(@expected_tacball_filename)

        txt_file_content = get_txt_file_content(@expected_tacball_filename)

        expected = @expected_text_template_content
        assert_false    expected.to_s.strip.empty?  ## verify I didn't make typo
        assert_match /#{expected}/, txt_file_content
      end
    end
  end

  def test_consume_txt_content_precedence_then_text
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        doc = @doc.dup
        doc.text = @expected_doc_text_content

        @tacball_consume_action.consume(doc)
        assert_true File.file?(@expected_tacball_filename)

        txt_file_content = get_txt_file_content(@expected_tacball_filename)

        expected = @expected_doc_text_content
        assert_false    expected.to_s.strip.empty?  ## verify I didn't make typo
        assert_match /#{expected}/, txt_file_content
      end
    end
  end

  def test_consume_txt_content_precedence_no_text
    Armagh::Actions::Loggable.expects(:logger).at_least(0)
    @sftp.expects(:put_file).at_least(0)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        doc = @doc.dup
        doc.content = {}
        doc.display = nil

        @tacball_consume_action.consume(doc)
        assert_true File.file?(@expected_tacball_filename)

        txt_file_content = get_txt_file_content(@expected_tacball_filename)

        assert_not_match /#{@expected_html_template_content}/, txt_file_content
        assert_not_match /#{@expected_text_template_content}/, txt_file_content
        assert_not_match /#{@expected_doc_display_content  }/, txt_file_content
        assert_not_match /#{@expected_doc_text_content     }/, txt_file_content
      end
    end
  end


  def get_html_file_content(tacball_file)
    html_file_content = nil

    tgz_hash = tgz_to_hash(tacball_file)
    tgz_hash.each do |fname, contents|
      html_file_content = contents  if fname =~ /\.html$/
    end

    return html_file_content
  end

  def get_txt_file_content(tacball_file)
    txt_file_content = nil

    tgz_hash = tgz_to_hash(tacball_file)
    tgz_hash.each do |fname, contents|
      txt_file_content = contents  if fname =~ /\.txt$/
    end

    return txt_file_content
  end

  def setup_tacball_consume_action_with_template
    Armagh::Actions.stubs(:available_templates).returns(['test/test_template.erubis (StandardActions'])
    Armagh::Actions.stubs(:get_template_path).with('test/test_template.erubis (StandardActions').returns('/some/full/path/test/test_template.erubis')
    load File.join(__dir__, '..', '..', '..', '..', 'lib', 'armagh', 'standard_actions', 'consumers', 'tacball_consume.rb')
    tacball_config_values = @tacball_config_values.dup
    tacball_config_values['tacball']['template'] = 'test/test_template.erubis (StandardActions'
    tacball_config = Armagh::StandardActions::TacballConsume.create_configuration([], 'test', tacball_config_values)
    tacball_consume_action_with_template = instantiate_action(Armagh::StandardActions::TacballConsume, tacball_config)
    tacball_consume_action_with_template.stubs(:logger)

    tacball_consume_action_with_template.stubs(:render_template).at_least(1).returns([@expected_text_template_content, @expected_html_template_content])

    return tacball_consume_action_with_template
  end
end
