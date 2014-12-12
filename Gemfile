source "https://rubygems.org"

#gem 'praxis', github: 'rightscale/praxis'
gem 'praxis', path: '../../rightscale/praxis'

gem 'attributor', github: 'rightscale/attributor'
gem 'praxis-blueprints', github: 'rightscale/praxis-blueprints'

gem 'rainbows', require: false
gem 'rake'
gem 'pry'
gem 'pry-byebug'

gem 'json-schema'

gem 'rack-cors', :require => 'rack/cors'

group :development, :test do
  gem "rack-test", :require => "rack/test"
  gem "rspec" # needed for rake task
  gem 'rspec-its'
  gem 'rspec-collection_matchers'

  gem 'foreman', :require => false

  gem 'shotgun', :require => false
  gem "guard"
  gem "guard-rspec"
end
