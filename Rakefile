require 'rake/testtask'
require 'rubygems/package_task'
require 'rdoc/task'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

gemspec = eval(File.read('simple_rrd.gemspec'))

Gem::PackageTask.new(gemspec) do |pkg|
end

### Task: rdoc
Rake::RDocTask.new do |rdoc|
  rdoc.title    = "SimpleRRD"

  rdoc.options += [
      '-w', '4',
      '-SHN',
      '-f', 'darkfish' # This bit
    ]
  
  rdoc.rdoc_files.include 'lib/simple_rrd.rb'
end



