Gem::Specification.new do |s|
  s.name        = 'simple_rrd'
  s.version     = '0.0.1'
  s.date        = '2014-01-03'
  s.summary     = "Simple RRD Interface"
  s.description = "Simplified Create, Read, Update, Delete wrapper for rrdtool"
  s.authors     = ["Michael Utke, Jr."]
  s.email       = 'mutke@shutterfly.com'
  s.homepage    = 'http://www.shutterfly.com'
  s.files       = ["lib/simple_rrd.rb"]
  s.license     = 'LGPL-2.1'
  s.requirements << 'rrdtool and its ruby bindings'
  s.test_files  = ['test/test_simple_rrd.rb']
  s.rubyforge_project = "simple-rrd"
  # s.extra_rdoc_files = ['README', 'doc/user-guide.txt']
end

