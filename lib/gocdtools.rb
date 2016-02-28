require 'gocdtools/version'
require 'rexml/document'
require 'openssl'
require 'base64'

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
  
  def self.reencrypt_secure_variables(opts={})
    required_args = :in_xml, :with_cipher_key, :and_provider
    required_args.each do |arg|
      if opts[arg].nil?
        throw ArgumentError::new "Need argument #{arg} to be set"
      end
    end
    
    xml, iv, get = opts.values_at :in_xml, :with_cipher_key, :and_provider
    xml.elements.each "//variable[@secure='true']" do |e|
      name = e.attribute 'name'
      secret = get.secret_for variable: name.to_s
      
      e.elements.each '//encryptedValue' do |encrypted_value|
        encrypted_value.text = Base64.encode64 des_encrypt secret, iv
      end
    end
  end 
end
