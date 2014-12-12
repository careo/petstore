# -p 8888

ENV['RACK_ENV'] ||= 'development'
Bundler.setup(:default, ENV['RACK_ENV'])
Bundler.require(:default, ENV['RACK_ENV'])

use Rack::Cors do
  allow do
    origins '*'
    resource '/*', :headers => :any, :methods => :any
  end
end

run Praxis::Application.instance.setup
