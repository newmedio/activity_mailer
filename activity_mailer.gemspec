Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name        = 'activity-mailer'
  s.version     = '0.0.7'
  s.date        = '2018-09-06'
  s.summary       = "Mandrill Templating Service Helper"
  s.authors     = ["Jonathan Bartlett"]
  s.email       = 'jonathan@newmedio.com'
  s.files       = [
	"lib/activity_mailer.rb"
  ]
  s.homepage    = "http://www.newmedio.com/"
  s.license       = 'MIT'
  s.require_path  = 'lib'

  s.add_runtime_dependency 'mandrill-api'
end
