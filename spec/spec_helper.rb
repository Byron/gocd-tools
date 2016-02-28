$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gocdtools'
require 'fileutils'
require 'openssl'

def new_iv()
  OpenSSL::Cipher::new('des').random_iv
end

def des_decrypt(value, iv)
  c = OpenSSL::Cipher::new('des')
  c.decrypt
  c.iv = iv
  res = c.update value
  res << c.final
end

def element_count(xml, xpath)
  c = 0
  xml.elements.each xpath do |e| c += 1 end
  c
end

def fixture_path(path)
  File.join(File::dirname(__FILE__), 'fixtures', path)
end

def load_fixture_as_stream(path)
  File::open fixture_path path
end

def write_file(path, contents)
  FileUtils::mkdir_p File::dirname path
  File::open(path, 'w') do |f|
    f.write contents
  end
end
