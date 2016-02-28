require 'spec_helper'
require 'rexml/document'
require 'gocdtools'
require 'tmpdir'
require 'fileutils'
require 'base64'

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
        expect{@provider.secret_for variable: 'NOT_THERE'}.to raise_error StandardError, /Tried paths/
      end
      
      it 'provides pipeline specific secrets before common secrets' do
        expect(@provider.secret_for pipeline: 'foo', variable: 'BAR').to eq 'foo/BAR'
      end
      
      it 'provides common secrets if there is no specific one, even if pipeline exists' do
        rela_path = File::join SecretsProvider::ANY, 'COMMON'
        expect(@provider.secret_for pipeline: 'foo', variable: 'COMMON').to eq rela_path
      end
      
      context "and xml doc and cipher key do" do
        let(:xml_doc) {
          xml_stream = load_fixture_as_stream('cruise-config.xml')
          REXML::Document::new xml_stream
        }
        iv = new_iv
        ENCRYPTED_MARKER = 'ENCRYPTED'
        XENCRYPTED_VALUES = "//encryptedValue[contains(text(),'#{ENCRYPTED_MARKER}')]"
        
        describe "reencrypt_secure_variables(..)" do
          it "will encrypt all secure variables" do
            expect(element_count xml_doc, XENCRYPTED_VALUES).to eq 2  
            GocdTools::reencrypt_secure_variables in_xml: xml_doc,
                                                  with_cipher_key: iv,
                                                  and_provider: @provider
            expect(element_count xml_doc, '//encryptedValue').to eq 2
            xml_doc.elements.each '//encryptedValue' do |e|
              plain = Base64.decode64 e.text.to_s
              expect(plain).not_to eq ENCRYPTED_MARKER
              expect(des_decrypt plain, iv).to match(/.*\/[A-Z]+/)
            end
          end
        end
      end
      
      describe "reencrypt_cruise_config_with_autocleanup()" do
        it "needs its own directory (to delete safely on cleanup)" do
          dir_exists = [ArgumentError, /.*directory.*must not exist.*/]
          expect{
            GocdTools::reencrypt_cruise_config_with_autocleanup(
                                      at: fixture_path('cruise-config.xml'),
                                      and_provider: @provider,
                                      into: @tmp_dir) }.to raise_error(*dir_exists)
        end
        
        it "writes_cipher_and_cruise_config_and_removes_it_on_process_done" do
          new_dir = File::join(@tmp_dir, 'yours-truly')
          pid = fork do
            allow(GocdTools).to receive :reencrypt_secure_variables
            allow(GocdTools).to receive :sanitize
            
            cipher_path, cruise_config_path =
            GocdTools::reencrypt_cruise_config_with_autocleanup(
                                      at: fixture_path('cruise-config.xml'),
                                      and_provider: @provider,
                                      into: new_dir)
            expect(GocdTools).to have_received :reencrypt_secure_variables                                
            expect(GocdTools).to have_received :sanitize
            expect(File::exist? cipher_path).to be true
            expect(File::exist? cruise_config_path).to be true
            
            bin_cipher_key = File::read(cipher_path).scan(/../).map { |x| x.hex.chr }.join
            expect(bin_cipher_key.size).to be_between(7, 8).inclusive
          end
          Process.wait pid
          expect(File::directory? new_dir).to be false
        end
      end
      
    end
  end
  
  RSpec.describe 'DES' do
    include GocdTools
    
    iv = new_iv
    
    VALUE = 'my fancy value'
    
    it 'can encrypt values' do
      expect(GocdTools::des_encrypt VALUE, iv).not_to eq VALUE
    end
    
    it 'can decrypt encrypted values with the same iv' do
      encrypted = GocdTools::des_encrypt VALUE, iv
      expect(des_decrypt encrypted, iv).to eq VALUE
    end
    
    it 'cannot decrypt encrypted values with different key' do
      encrypted = GocdTools::des_encrypt VALUE, iv
      expect(des_decrypt encrypted, new_iv).not_to eq VALUE
    end
  end
  
end
