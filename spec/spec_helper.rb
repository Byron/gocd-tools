$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gocdtools'
require 'fileutils'
def load_fixture_as_stream(path)
  File::open File.join(File::dirname(__FILE__), 'fixtures', path)
end

def write_file(path, contents)
  FileUtils::mkdir_p File::dirname path
  File::open(path, 'w') do |f|
    f.write contents
  end
end
