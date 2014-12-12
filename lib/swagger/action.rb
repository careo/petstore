module Swagger
  class Action
    attr_reader :config, :params_in_path
    
    def initialize( config: , params_in_path: )
      @config = config
      @params_in_path = params_in_path
    end
    
    def generate

      data =  {
        operationId: config.name,
        description: config.description,
        responses: {}
      }

      # Parameters
      parameters = generate_parameters
      if parameters.any?
        data[:parameters] = parameters
      end

      # Produces and Responses
      produces = []
      responses = {}

      config.responses.each do |name, response|
        if response.media_type
          produces << response.media_type.identifier
        end

        if responses.key? response.status.to_s
          warn "already have response for status: #{response.status} for #{action.name}"
        end
        responses[response.status.to_s] = Response.new(response_definition: response).generate
      end
      data[:produces] = produces.uniq.compact
      data[:responses] = responses

      data      
    end

    def generate_parameters
      # Parameters
      parameters = []
      if config.params
        config.params.attributes.each do |name, param|
          parameter = generate_parameter(name, param)
          parameter[:in] = if params_in_path.include?(name.to_s)
            'path'
          else
            'query'
          end
          parameters << parameter
        end
      end

      if config.payload        
        # NOTE:  'payload' name does not matter for payload bodies
        parameter = generate_parameter( 'payload', config.payload )
        parameter[:in] = 'body'
        parameter.merge!( Swagger::Type.for(config.payload) )

        parameters << parameter
      end
      parameters
    end
    
    def generate_parameter( name, attribute )
      parameter = {
        name: name.to_s,
        required: attribute.options.fetch(:required, false)
      }

      parameter.merge!(Type.for(attribute.type))

      if (desc = attribute.options[:description])
        parameter[:description] = desc
      end
      parameter
    end
    
  end
end