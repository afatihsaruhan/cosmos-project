# encoding: ascii-8bit

Gem::Specification.new do |s|
  s.name = 'openc3-cosmos-rm3100'
  s.summary = 'GZGN-EIU RM3100 magnetometer target for OpenC3 COSMOS'
  s.description = <<-EOF
    Commands and telemetry of the GZGN-EIU RM3100 proof of concept
    (NUCLEO-H723ZG), carried as raw CCSDS packets through a TCP bridge.
  EOF
  s.authors = ['afatihsaruhan']
  s.homepage = 'https://github.com/afatihsaruhan/cosmos-project'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0'

  if ENV['VERSION']
    s.version = ENV['VERSION'].dup
  else
    time = Time.now.strftime("%Y%m%d%H%M%S")
    s.version = '0.0.0' + ".#{time}"
  end
  s.files = Dir.glob("{targets,lib,public,tools,microservices}/**/*") + %w(Rakefile README.md plugin.txt)
  s.files = s.files.reject { |file| file.include?('__pycache__') }
  s.metadata = { "openc3_cosmos_minimum_version" => "7.4.0" }
end
