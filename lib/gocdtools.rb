require 'gocdtools/version'
require 'rexml/document'
require 'openssl'
require 'base64'
require 'fileutils'

module GocdTools
  # Provides secrets for environment variables by looking up their name in a directory on disk,
  # assuming the file contents is the decrypted secret to provide.
  class SecretsProvider
    ANY = '_any-pipeline_'
    
    def initialize(root_directory)
      throw ArgumentError::new "#{root_directory} does not exist" unless File::directory? root_directory
      @root = root_directory
    end
    
    def secret_for(opts={})
      if (variable = opts[:variable]).nil?
        throw ArgumentError::new "need :variable"
      end
      
      subdirs_to_check = [ANY]
      unless (pipeline = opts[:pipeline]).nil?
        subdirs_to_check.unshift pipeline
      end
      
      paths = []
      subdirs_to_check.each do |sd|
        path = File::join @root, sd, variable
        paths.push path
        begin
          return File::read path
        rescue
        end
      end
      
      msg = "No secret found for '#{variable}' in pipeline '#{pipeline || 'unspecified'}'"
      msg += "\nTried paths: \n#{paths.join '\n'}"
      throw StandardError::new msg
    end
  end
  
  def self.sanitize(xml_doc)
    xml_doc.delete_element '//agent'
    xml_doc.delete_element '//environment'
  end  
  
  def self.des_encrypt(value, iv)
    c = OpenSSL::Cipher::new('des')
    c.encrypt
    c.iv = iv
    res = c.update value
    res << c.final
  end
  
  M = '<ARGUMENT MUST BE SET>'
  def self.reencrypt_secure_variables(in_xml: M, with_cipher_key: M, and_provider: M)
    xml, iv, get = in_xml, with_cipher_key, and_provider
    xml.elements.each "//variable[@secure='true']" do |e|
      name = e.attribute 'name'
      secret = get.secret_for variable: name.to_s
      
      e.elements.each '//encryptedValue' do |encrypted_value|
        encrypted_value.text = Base64.encode64 des_encrypt secret, iv
      end
    end
  end
  
  def self.reencrypt_cruise_config_with_autocleanup(at: M, and_provider: M, into: M)
    if File::directory? into
      throw ArgumentError::new "directory '#{into}' must not exist"
    end
    
    FileUtils::mkdir into
    
    f = File::open at
    xml = REXML::Document::new f
    f.close
    
    iv = OpenSSL::Cipher::new('des').random_iv
    reencrypt_secure_variables in_xml: xml, with_cipher_key: iv, and_provider: and_provider
    
    cfp = File::join into, 'cipher'
    cf = File::new cfp, 'w'
    cf.write iv.each_byte.map { |b| b.to_s 16 }.join
    cf.close
    
    ccfp = File::join into, 'cruise-config.xml'
    ccf = File::new ccfp, 'w'
    xml.write ccf
    ccf.close
      
    at_exit { FileUtils::rm_rf into }
    
    [cfp, ccfp]
  end
end