require 'spec_helper'
require 'rexml/document'

describe GocdTools do
  it 'has a version number' do
    expect(GocdTools::VERSION).not_to be nil
  end
  
  include GocdTools
  
  it 'will remove agents and secrets when sanitizing' do
    xml_stream = load_fixture_as_stream('cruise-config.xml')
    xml_doc = REXML::Document::new xml_stream
    expect(xml_doc.elements['//agent']).not_to be_nil
    expect(xml_doc.elements["//variable[@secure='true']"]).not_to be_nil
    sanitize xml_doc
    expect(xml_doc.elements['//agent']).to be nil
  end
end
