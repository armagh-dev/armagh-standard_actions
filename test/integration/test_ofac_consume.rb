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

require 'test/unit'
require 'fakefs/safe'
require 'mocha/test_unit'
require 'bson'

PREFIX = ENV['ARMAGH_TAC_DOC_PREFIX']
ENV['ARMAGH_TAC_DOC_PREFIX'] = '4025'

require_relative '../helpers/actions_test_helper'
require_relative '../../lib/armagh/standard_actions/consumers/ofac_consume'

class TestIntegrationOfacConsume < Test::Unit::TestCase

  include ActionsTestHelper

  READ_WRITE_DIR = 'readwrite_dir/tacballs'

  def setup
    local_integration_test_config = load_local_integration_test_config
    @host = local_integration_test_config['test_sftp_host']
    @username = local_integration_test_config['test_sftp_username']
    @password = local_integration_test_config['test_sftp_password']
    @port = local_integration_test_config['test_sftp_port']
    @directory_path = READ_WRITE_DIR

    @sftp_config_values = {
      'host' => @host,
      'username' => @username,
      'password' => @password,
      'directory_path' => @directory_path,
      'create_directory_path' => true,
      'port' => @port
    }

    @config_values = {
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dan_indoc', Armagh::Documents::DocState::PUBLISHED )},
      'sftp' => @sftp_config_values,
      'tacball' => {
        'feed' => 'carnitas',
        'source' => 'chipotle'
      }
    }

    @fixtures_path = File.join(__dir__, '..', 'fixtures')
    @ofac_input_path = File.join(@fixtures_path, "ofac_input")
    @ofac_output_path = File.join(@fixtures_path, "ofac_output")

    @config = Armagh::StandardActions::OfacConsume.create_configuration([], 'test', @config_values)
    @ofac_consume = instantiate_action(Armagh::StandardActions::OfacConsume, @config)
    @docspec = Armagh::Documents::DocSpec.new('DocType', Armagh::Documents::DocState::READY)

    @entity_content                = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_entity.yml')))
    @entity_content_with_no_knowns = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_entity_no_knowns.yml')))

    @aircraft_content                = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_aircraft.yml')))
    @aircraft_content_with_no_knowns = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_aircraft_no_knowns.yml')))

    @individual_content                = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_individual.yml')))
    @individual_content_with_no_knowns = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_individual_no_knowns.yml')))

    @vessel_content                = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_vessel.yml')))
    @vessel_content_with_no_knowns = YAML.load(File.read(File.join(@ofac_input_path, 'sdn_vessel_no_knowns.yml')))
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def self.shutdown
    ENV['ARMAGH_TAC_DOC_PREFIX'] = PREFIX
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

  def doc_with_content(content)
    Armagh::Documents::ActionDocument.new(
      document_id:        'dd123',
      title:              'Halloween Parade',
      copyright:          '2016 - All Rights Reserved',
      content:            content,
      metadata:           {'meta' => true},
      docspec:            @docspec,
      source:             'chipotle',
      document_timestamp: 1451696523,
      display:            'The school parade was fun'
    )
  end


  test "#consume where entity content has known values for each heading" do
    doc = doc_with_content(@entity_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_entity_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where entity content doesn't have known values for each heading" do
    doc = doc_with_content(@entity_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_entity_no_knowns_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where aircraft content has known values for each heading" do
    doc = doc_with_content(@aircraft_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_aircraft_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where aircraft content doesn't have known values for each heading" do
    doc = doc_with_content(@aircraft_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_aircraft_no_knowns_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where individual content has known values for each heading" do
    doc = doc_with_content(@individual_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_individual_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where individual content doesn't have known values for each heading" do
    doc = doc_with_content(@individual_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_individual_no_knowns_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where vessel content has known values for each heading" do
    doc = doc_with_content(@vessel_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_vessel_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#consume where vessel content doesn't have known values for each heading" do
    doc = doc_with_content(@vessel_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_vessel_no_knowns_sample.txt'))

    assert_equal text_content, expected_text_content
  end

  test "#template_path when @node_type is set" do
    doc = doc_with_content(@entity_content)
    @ofac_consume.instance_variable_set(:@node_type, "vessel")
    template_file_name = File.basename @ofac_consume.template_path(doc)
    assert_equal template_file_name, "vessel_template.erubis"
  end

  test "#template_path when @node_type is not set" do
    doc = doc_with_content(@entity_content)
    template_file_name = File.basename @ofac_consume.template_path(doc)
    assert_equal template_file_name, "entity_template.erubis"
  end

end
