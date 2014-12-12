module Swagger
  class Preface
    attr_reader :version
    def initialize( version: , **options )
      @version = version
    end
    def generate
      {
        swagger: '2.0',
        info: {
          version: version,
          title: 'RightSwagger Petstore',
          description: 'A sample API that uses a petstore as an example to demonstrate features in the swagger-2.0 specification',
          termsOfService: 'http://example.com/terms/',
          contact: {
            name: 'RightSwagger API team',
            email: 'foo@example.com',
            url: 'http://swagger.io'
          },
          license: {
            name: 'MIT',
            url: 'http://opensource.org/licenses/MIT'
          },
        },
        host: 'localhost:9292',
        basePath: '/',
        schemes: ['http'],
        consumes: ['application/json'],
        produces: ['application/json'],
      }
    end
  end
  
end