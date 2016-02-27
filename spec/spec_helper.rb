$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gocdtools'

def load_fixture_as_stream(path)
  File::open File.join(File::dirname(__FILE__), 'fixtures', path)
end
