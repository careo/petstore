# -p 8888

ENV['RACK_ENV'] ||= 'development'
Bundler.setup(:default, ENV['RACK_ENV'])
Bundler.require(:default, ENV['RACK_ENV'])


use Rack::Cors do
  allow do
    origins '*'
    resource '/swagger/*', :headers => :any, :methods => [ :get, :options ]
    resource '/api/*', :headers => :any, :methods => [ :get, :post, :put, :patch, :delete, :options ]
  end
end

map "/swagger" do # application JSON docs
  use Rack::Static, urls: [""], root: File.join(Dir.pwd, Praxis::SwaggerDocGenerator::API_DOCS_DIRNAME)
end

run Praxis::Application.instance.setup
