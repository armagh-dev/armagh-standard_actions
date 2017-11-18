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
require 'mocha/test_unit'

require_relative '../helpers/actions_test_helper'
require_relative '../../lib/armagh/standard_actions/consumers/tacball_consume'

class TestIntegrationTacballConsumeForOfac < Test::Unit::TestCase

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
      'port' => @port
    }

    @config_values = {
        'action' => { 'workflow' => 'wf'},
      'input' => { 'docspec' => Armagh::Documents::DocSpec.new( 'dan_indoc', Armagh::Documents::DocState::PUBLISHED )},
      'sftp' => @sftp_config_values,
      'tacball' => {
        'feed' => 'carnitas',
        'source' => 'chipotle',
        'docid_prefix' => '4026',
        'template' => 'ofac/ofac.erubis (StandardActions)'
      }
    }

    @fixtures_path = File.join(__dir__, '..', 'fixtures')
    @ofac_input_path = File.join(@fixtures_path, "ofac_input")
    @ofac_output_path = File.join(@fixtures_path, "ofac_output")

    @config = Armagh::StandardActions::TacballConsume.create_configuration([], 'test', @config_values)
    @ofac_consume = instantiate_action(Armagh::StandardActions::TacballConsume, @config)
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
    Dir.glob("DocType*tgz*") { |p| File.delete(p) }
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
      raw:                nil,
      metadata:           {'meta' => true},
      docspec:            @docspec,
      source:             'chipotle',
      document_timestamp: 1451696523,
      display:            'The school parade was fun'
    )
  end

  def test_consume_where_entity_content_has_known_values_for_each_heading
    doc = doc_with_content(@entity_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_entity_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_entity_content_doesnt_have_known_values_for_each_heading
    doc = doc_with_content(@entity_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_entity_no_knowns_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_aircraft_content_has_known_values_for_each_heading
    doc = doc_with_content(@aircraft_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_aircraft_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_aircraft_content_doesnt_have_known_values_for_each_heading
    doc = doc_with_content(@aircraft_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_aircraft_no_knowns_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_individual_content_has_known_values_for_each_heading
    doc = doc_with_content(@individual_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_individual_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_individual_content_doesnt_have_known_values_for_each_heading
    doc = doc_with_content(@individual_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_individual_no_knowns_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_vessel_content_has_known_values_for_each_heading
    doc = doc_with_content(@vessel_content)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_vessel_sample.txt'))

    assert_equal expected_text_content, text_content
  end

  def test_consume_where_vessel_content_doesnt_have_known_values_for_each_heading
    doc = doc_with_content(@vessel_content_with_no_knowns)
    @ofac_consume.stubs(:logger).once
    filename = @ofac_consume.filename_from_doc(doc)
    hash = tgz_to_hash(filename)
    text_content = hash.values.last #pulling the .txt file from the tacball
    expected_text_content = File.read(File.join(@ofac_output_path, 'ofac_vessel_no_knowns_sample.txt'))

    assert_equal expected_text_content, text_content
  end

end
