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

# TODO This will eventually need to be added to the generator or moved to base actions.

require 'test-unit'
require 'mocha/test_unit'
require 'configh'

module ActionsTestHelper
  def instantiate_action(action_class, config)
    unless @caller
      @caller = mock('caller')
      @logger ||= mock('logger')
      @caller.stubs(:get_logger).returns(@logger)
    end

    @caller.stubs(:log_debug)
    @caller.stubs(:log_info)

    unless config.is_a?(Configh::Configuration)
      action = mock('action')
      action.stubs(:name).returns('test_action_name')
      config.stubs(:action).returns(action)
    end

    action_class.new( @caller, 'logger_name', config )
  end

  def assert_create(test_item, &block)
    assert_equal(test_item.method(:create).parameters.length, block.arity, 'The number of arguments passed into the assert_create block were not the same number expected by create.')

    test_item.expects(:create).with do |parameters|
      document_id = parameters[:document_id]
      title = parameters[:title]
      copyright = parameters[:copyright]
      document_timestamp = parameters[:document_timestamp]
      collected = parameters[:collected]
      metadata = parameters[:metadata]
      docspec_name = parameters[:docspec_name]
      source = parameters[:source]

      assert_true(document_id.nil? || document_id.is_a?(String), 'document_id must be nil or a string')
      assert_true(title.nil? || title.is_a?(String), 'title must be nil or a string')
      assert_true(copyright.nil? || copyright.is_a?(String), 'copyright must be nil or a string')
      assert_true(document_timestamp.nil? || document_timestamp.is_a?(Time), 'document_timestamp must be nil or a time')
      assert_true(docspec_name.nil? || docspec_name.is_a?(String), 'docspec_name must be a string unless using the default')
      assert_kind_of(String, collected, 'collected must be a String')
      assert_kind_of(Hash, metadata, 'metadata must be a Hash')
      assert_kind_of(Armagh::Documents::Source, source, 'source must be a Source')

      block.call document_id, title, copyright, document_timestamp, collected, metadata, docspec_name, source
      true
    end
  end

  def assert_edit
    # TODO Unimplemented
  end

  def assert_notify_ops(test_item, &block)
    assert_equal(test_item.method(:notify_ops).arity, block.arity, 'The number of arguments passed into the assert_notify_ops block were not the same number expected by notify_ops.')

    test_item.expects(:notify_ops).with do |error|
      block.call error
      true
    end
  end

  def assert_notify_dev(test_item, &block)
    assert_equal(test_item.method(:notify_dev).arity, block.arity, 'The number of arguments passed into the assert_notify_dev block were not the same number expected by notify_dev.')

    test_item.expects(:notify_dev).with do |error|
      block.call error
      true
    end
  end

  def tgz_to_hash(file)
    h = {}
    tar = Gem::Package::TarReader.new(Zlib::GzipReader.open(file))
    tar.rewind
    tar.each do |entry|
      content = entry.file? ? entry.read : nil
      h[entry.full_name] = content
    end
    tar.close
    h
  end
end
