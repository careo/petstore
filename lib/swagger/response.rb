module Swagger
  class Response 
    attr_reader :response_definition
    
    def initialize( response_definition: )
      @response_definition = response_definition
    end

    # description	string	Required. A short description of the response. GFM syntax can be used for rich text representation.
    # schema	Schema Object	A definition of the response structure. It can be a primitive, an array or an object. If this field does not exist, it means no content is returned as part of the response. As an extension to the Schema Object, its root type value may also be "file". This SHOULD be accompanied by a relevant produces mime-type.
    # headers	Headers Object	A list of headers that are sent with the response.
    # examples	Example Object	An example of the response message.
    def generate
      val = {}
      
      val[:description] = response_definition.description if response_definition.description
      
      # I believe any media_type object must appear in the top-level definition so we should simply reference 
      if (mt = response_definition.media_type)
        val[:schema] = {'$ref' => "#/definitions/#{mt.name}"} 
      end      

      val[:headers] = generate_headers if response_definition.headers.any?
      
      # TODO: We could easily generate examples here...
      # val[:examples] = "....."
      
      val
    end
    
    def generate_headers
      response_definition.headers.each_with_object({}) do |(name, definition),hash|
        
        hash[name] = case definition
        when nil, true
          warn "Not sure how to indicate just any value for a header. defaulting to string"
          {type: 'string'}
        when String
          {type: 'string'}
        when Regexp
          warn "Regexp valued headers in responses do not have a way to be presented in swagger...defaulting to string."
          {type: 'string'}
        else
          raise "Do not know how to handle a header value of #{definition} in a response"
        end
      end

    end
  end
end