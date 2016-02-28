require 'spec_helper'
require 'rexml/document'
require 'gocdtools'
require 'tmpdir'
require 'fileutils'

describe GocdTools do
  it 'has a version number' do
    expect(GocdTools::VERSION).not_to be nil
  end
end

module GocdTools  
  RSpec.describe 'sanitize()' do
    it 'will remove agents and secrets' do
      xml_stream = load_fixture_as_stream('cruise-config.xml')
      xml_doc = REXML::Document::new xml_stream
      
      expect(xml_doc.elements['//agent']).not_to be_nil
      expect(xml_doc.elements["//variable[@secure='true']"]).not_to be_nil
      expect(xml_doc.elements["//variable"]).not_to be_nil
      
      GocdTools::sanitize xml_doc
      
      expect(xml_doc.elements['//agent']).to be nil
      expect(xml_doc.elements["//variable"]).not_to be_nil
    end
  end
  
  RSpec.describe 'SecretsProvider' do
    let(:invalid_provider) { SecretsProvider::new 'hello' }
    
    it 'fails clearly if root is invalid' do
      expect{invalid_provider}.to raise_error ArgumentError
    end
    
    context 'with secrets directory' do
      before do
        @tmp_dir = Dir::mktmpdir 
        
        [SecretsProvider::ANY, 'foo'].each do |subdir|
          afp = File::join @tmp_dir, subdir
          FileUtils::mkdir afp
          fn = 'BAR'
          File::open(File::join(afp, fn), 'w') do |f|
            f.write File::join subdir, fn
          end
         end
        @provider = SecretsProvider::new @tmp_dir
      end
      
      after do 
        FileUtils.rm_rf @tmp_dir
      end
      
      it 'throws if no variable is given' do
        expect{@provider.secret_for pipeline: 'egal'}.to raise_error ArgumentError
      end
      
      it 'throws if there is no secret' do
        expect{@provider.secret_for variable: 'NOT_THERE'}.to raise_error StandardError
      end
      
      it 'provides pipeline specific secrets before common secrets' do
        expect(@provider.secret_for pipeline: 'foo', variable: 'BAR').to eq 'foo/BAR'
      end
    end
  end
end
