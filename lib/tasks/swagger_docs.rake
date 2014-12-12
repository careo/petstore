namespace :praxis do
  namespace :swagger do

    desc "Generate API docs (JSON definitions) for a Praxis App in Swagger format"
    task :generate => [:environment] do |t, args|
      require 'fileutils'

      Praxis::Blueprint.caching_enabled = false
      Praxis::SwaggerDocGenerator.new(Dir.pwd)
    end

    desc "Validate API docs against Swagger 2.0 schema"
    task :validate do
      require 'json-schema'
      schema_path = 'swagger-2.0.json'
      doc_path = 'swagger_docs/1.0.0/swagger.json'

      errors = JSON::Validator.fully_validate(schema_path, doc_path, errors_as_objects: true)
      puts "Error count: #{errors.size}"
      errors.each do |error|
        pp error
      end
    end

  end
end