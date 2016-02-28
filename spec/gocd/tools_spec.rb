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
          fn = 'BAR'
          path = File::join @tmp_dir, subdir, fn
          contents = File::join subdir, fn
          write_file path, contents
        end
        rela_path = File::join(SecretsProvider::ANY, 'COMMON')
        write_file File::join(@tmp_dir, rela_path), rela_path
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
      
      it 'provides common secrets if there is no specific one, even if pipeline exists' do
        rela_path = File::join SecretsProvider::ANY, 'COMMON'
        expect(@provider.secret_for pipeline: 'foo', variable: 'COMMON').to eq rela_path
      end
    end
  end
  
  RSpec.describe 'DES' do
    require 'openssl'
    include GocdTools
    
    new_iv =  lambda { OpenSSL::Cipher::new('des').random_iv }
    iv = new_iv.call
    
    VALUE = 'my fancy value'
    
    it 'can encrypt values' do
      expect(des_encrypt VALUE, iv).not_to eq VALUE
    end
    
    it 'can decrypt encrypted values with the same iv' do
      encrypted = des_encrypt VALUE, iv
      expect(des_decrypt encrypted, iv).to eq VALUE
    end
    
    it 'cannot decrypt encrypted values with different key' do
      encrypted = des_encrypt VALUE, iv
      expect(des_decrypt encrypted, new_iv.call).not_to eq VALUE
    end
  end
  
end
