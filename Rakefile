lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack/decorator'
 
task :build do
  system "gem build rack-decorator.gemspec"
end
 
task :release => :build do
  system "gem push rack-decorator-#{Rack::Decorator::VERSION}"
end