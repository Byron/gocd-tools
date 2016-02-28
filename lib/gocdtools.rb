require 'gocdtools/version'
require 'rexml/document'

module GocdTools
  # Provides secrets for environment variables by looking up their name in a directory on disk,
  # assuming the file contents is the decrypted secret to provide.
  class SecretsProvider
    ANY = '_any-pipeline_'
    
    def initialize(root_directory)
      throw ArgumentError::new "#{root_directory} does not exist" unless File::directory? root_directory
      @root = root_directory
    end
    
    def secret_for(options={})
      if (variable = options[:variable]).nil?
        throw ArgumentError::new "need :variable"
      end
      
      subdirs_to_check = [ANY]
      unless (pipeline = options[:pipeline]).nil?
        subdirs_to_check.unshift pipeline
      end
      
      subdirs_to_check.each do |sd|
        begin
          return File::read File::join(@root, sd, variable)
        rescue
        end
      end
      
      throw StandardError::new "No secret found for '#{variable}' in pipeline '#{pipeline || ANY}'"
    end
  end
  
  def self.sanitize(xml_doc)
    xml_doc.delete_element '//agent'
    xml_doc.delete_element '//environment'
  end  
end
