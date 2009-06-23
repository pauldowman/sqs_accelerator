spec = Gem::Specification.new do |s|
  s.name = 'sqs_accelerator'
  s.version = '0.0.1'
  s.date = '2009-06-22'
  s.summary = 'SQS Accelerator'
  s.description = "A simple evented server that proxies requests to Amazon's Simple Queue Service to queue messages very quickly."
  s.email = 'paul@pauldowman.com'
  s.homepage = "http://github.com/pauldowman/sqs-accelerator"
  s.has_rdoc = false
  s.authors = ["Paul Dowman"]
  s.add_dependency('eventmachine', '>= 0.12.2')
  s.add_dependency('igrigorik-em-http-request', '>= 0.1.6')
  s.add_dependency('sinatra', '>= 0.9.2')
  s.add_dependency('async_sinatra', '>= 0.1.4')
  s.add_dependency('libxml-ruby', '>= 1.1.3')
  s.rubyforge_project = "sqs-accelerator"

  # ruby -rpp -e' pp `git ls-files`.split("\n") '
  s.files = ["README.markdown",
   "lib/server.rb",
   "lib/sqs_accelerator.rb",
   "lib/sqs_helper.rb",
   "lib/sqs_proxy.rb",
   "sqs_accelerator.gemspec",
   "sqs_accelerator.ru",
   "views/all_queues.haml",
   "views/home.haml",
   "views/queue_info.haml"]
  
end
