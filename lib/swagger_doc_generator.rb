module Praxis
  class SwaggerDocGenerator

    class << self
      attr_reader :inspected_types
    end

    @inspected_types = Set.new
    API_DOCS_DIRNAME = 'swagger_docs'

    EXCLUDED_TYPES_FROM_TOP_LEVEL = Set.new( [Attributor::Boolean, Attributor::CSV, Attributor::DateTime, Attributor::Float, Attributor::Hash, Attributor::Ids, Attributor::Integer, Attributor::Object,  Attributor::String ] ).freeze

    def self.inspect_attributes(the_type)
      reachable = Set.new
      return reachable if the_type.nil? || the_type.is_a?(Praxis::SimpleMediaType)

      # If an attribute comes in, get its type
      the_type = the_type.type if the_type.is_a? Attributor::Attribute

      # Collection types are special since they wrap a member type, so let's reach in and grab it
      the_type = the_type.member_attribute.type if the_type < Attributor::Collection

      if @inspected_types.include? the_type
        # We're done if we've already inspected it
        return reachable
      else
        # Mark it as inspected (before recursing)
        @inspected_types << the_type  unless the_type.name == nil # Don't bother with anon structs
      end
      #puts "Inspecting type: #{the_type.name}"    if the_type.name != nil

      reachable << the_type  unless the_type.name == nil # Don't bother with anon structs
      if the_type.respond_to? :attributes
        the_type.attributes.each do |name, attr|
          attr_type = attr.type
          #puts "Inspecting attr: #{name} (class: #{attr_type.name}) #{attr_type.inspect}"
          reachable += self.inspect_attributes(attr_type)
        end
      end
      reachable
    end

    class Resource

      attr_accessor :media_type, :reachable_types, :version, :controller_config

      def initialize( definition )
        @controller_config = definition
        if controller_config.version == 'n/a'
          @version = 'unversioned'
        else
          @version = controller_config.version
        end
        @media_type = controller_config.media_type
        @reachable_types = Set.new

        # Collect reachable types from the media_type if any (plus itself)
        if @media_type && ! @media_type.is_a?(Praxis::SimpleMediaType)
          add_to_reachable SwaggerDocGenerator.inspect_attributes(@media_type)
          @media_type.attributes.each do |name, attr|
            add_to_reachable SwaggerDocGenerator.inspect_attributes(attr)
          end
          @generated_example = @media_type.example(self.id)
        end

        # Collect reachable types from the params and payload definitions
        @controller_config.actions.each do |name, action_config|
          add_to_reachable SwaggerDocGenerator.inspect_attributes(action_config.params)
          add_to_reachable SwaggerDocGenerator.inspect_attributes(action_config.payload)
          action_config.responses.each do |response_name, response|
            if response.media_type
              add_to_reachable SwaggerDocGenerator.inspect_attributes(response.media_type)
            end
          end
        end
      end

      # TODO: I think that the "id"/"name" of a resource should be provided by the definition/controller...not derived here
      def id
        if @controller_config.controller
          @controller_config.controller.name
        else
          # If an API doesn't quite have the controller defined, let's use the name from the resource definition
          @controller_config.name
        end
      end

      def add_to_reachable( found )
        return if found == nil
        @reachable_types += found
      end
    end

    def initialize(root_dir)
      @root_dir = root_dir
      @doc_root_dir = File.join(@root_dir, API_DOCS_DIRNAME)
      @resources = []

      remove_previous_doc_data
      load_resources

      # Gather all reachable types (grouped by version)
      types_for = Hash.new
      @resources.each do |r|
        types_for[r.version] ||= Set.new
        types_for[r.version] += r.reachable_types
      end

      types_for.each do |version, types|
        preface = swagger_preface(version)
        resources = @resources.select { |r| r.version == version }


        paths = {}
        resources.each do |resource|
          resource.controller_config.actions.each do |name, action_config|

            action_config.routes.each do |route|
              data = action_stuff(action_config, route)

              path = route.path.to_templates.first
              verb = route.verb.downcase
              paths[path] ||= {}
              paths[path][verb] = data
            end
          end
        end

        definitions = {}
        types.each do |type|
          next if EXCLUDED_TYPES_FROM_TOP_LEVEL.include?(type)
          name = type.name


          definitions[name] = type_stuff(type)
        end

        doc = preface

        doc[:paths] = paths
        doc[:definitions] = definitions

        filename = File.join(@doc_root_dir, version, "swagger.json")
        base = File.dirname(filename)
        FileUtils.mkdir_p base unless File.exists? base
        File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(doc))}
      end



      #write_swagger
      #write_resources
      #write_types(types_for)
      #write_index(types_for)

      #save_doc
    end

    def action_stuff(action_config, route)

      data =  {
        operationId: action_config.name,
        description: action_config.description,
        responses: {}
      }

      produces = []
      responses = {}

      action_config.responses.each do |name, response|
        if response.media_type
          produces << response.media_type.identifier
        end

        if responses.key? response.status.to_s
          warn "already have response for status: #{response.status} for #{action.name}"
        end
        responses[response.status.to_s] = response_stuff(response)
      end

      parameters = []
      if action_config.params
        action_config.params.attributes.each do |name, param|
          parameter = {
            name: name.to_s,
            required: param.options.fetch(:required, false)
          }

          parameter.merge!(swagger_type_for(param.type))

          if (desc = param.options[:description])
            parameter[:description] = desc
          end

          parameter[:in] = if route.path.named_captures.key?(name.to_s)
            'path'
          else
            'query'
          end

          parameters << parameter
        end
      end

      if action_config.payload
        action_config.payload.attributes.each do |name, param|
          parameter = {
            name: name.to_s,
            required: param.options.fetch(:required, false)
          }

          parameter.merge!(swagger_type_for(param.type))

          if (desc = param.options[:description])
            parameter[:description] = desc
          end

          parameter[:in] = 'body' # TODO: form? that includes multi-part...

          parameters << parameter
        end
      end

      data[:produces] = produces.uniq.compact
      data[:responses] = responses

      if parameters.any?
        data[:parameters] = parameters
      end

      data
    end

    def swagger_type_for(attribute)
      if attribute.kind_of? Attributor::Attribute
        type = attribute.type
      else
        type = attribute
      end

      if type == Attributor::Integer
        return {type: 'integer', format: 'int32'}
      elsif type == Attributor::String
        return {type: 'string'}
      elsif type.ancestors.include?(Attributor::Collection)
        val = {type: 'array', items: swagger_type_for(type.member_attribute.type)}
        if type.ancestors.include?(Attributor::CSV)
          val[:collectionFormat] = 'csv'
        end
        return val
      elsif type.attributes.any?
        return {schema: type_stuff(type) } 
      else
        binding.pry
        raise "unknown type: #{type.inspect}"
      end
    end



    def response_stuff(response)

      val = {}
      if (desc = response.description)
        val[:description] = desc
      end

      if (mt = response.media_type)
        val[:schema] = {'$ref' => "#/definitions/#{mt.name}"}
      end

      headers = {} #TODO


      val

    end


    def type_stuff(type)
      if type.ancestors.include?(Praxis::MediaTypeCollection)
        return {
          type: 'array',
          items: {
            '$ref' => "#/definitions/#{type.member_attribute.type.name}"
          }
        }
      else

        required = type.attributes.each_with_object([]) do |(name, attribute), array|
          array << name if attribute.options[:required]
        end

        properties = {}
        type.attributes.each do |name, attribute|
          properties[name] = swagger_type_for(attribute)
        end

        val = {properties: properties}
        if required.any?
          val[:required] = required
        end
        val
      end
    end

    def load_resources
      Praxis::Application.instance.resource_definitions.map do |resource|
        @resources << Resource.new(resource)
      end

    end

    def dump_example_for(context_name, object)
      example = object.example(Array(context_name))
      if object.is_a? Praxis::Blueprint
        example.render(:master)
      elsif object.is_a? Attributor::Attribute
        object.dump(example)
      else
        raise "Do not know how to dump this object (it is not a Blueprint or an Attribute): #{object}"
      end
    end

    def swagger_preface(version)
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

    def write_resources(resources)
      resources.each do |r|
        #filename = File.join(@doc_root_dir, r.version, "resources","#{r.id}.json")
        #puts "Dumping #{r.id} to #{filename}"
        #base = File.dirname(filename)
        #FileUtils.mkdir_p base unless File.exists? base
        resource_description = r.controller_config.describe
        # Go through the params/payload of each action and generate an example for them (then stick it into the description hash)
        r.controller_config.actions.each do |action_name, action|
          generated_examples = {}
          if action.params
            generated_examples[:params] = dump_example_for( r.id, action.params )
          end
          if action.payload
            generated_examples[:payload] = dump_example_for( r.id, action.payload )
          end
          action_description = resource_description[:actions].find{|a| a[:name] == action_name }
          action_description[:params][:example] = generated_examples[:params] if generated_examples[:params]
          action_description[:payload][:example] = generated_examples[:payload] if generated_examples[:payload]
        end

        #File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(resource_description))}
      end
    end

    def write_types( versioned_types )
      versioned_types.each do |version, types|
        dirname = File.join(@doc_root_dir, version, "types")
        FileUtils.mkdir_p dirname unless File.exists? dirname
        reportable_types = types - EXCLUDED_TYPES_FROM_TOP_LEVEL
        reportable_types.each do |type|
          filename = File.join(dirname, "#{type.name}.json")
          #puts "Dumping #{type.name} to #{filename}"
          type_output = type.describe
          example_data = type.example(type.to_s)
          if type_output[:views]
            type_output[:views].delete(:master)
            type_output[:views].each do |view_name, view_info|
              # Add and example for each view
              unless( type < Praxis::Links ) #TODO: why do we need to skip an example for links?
                view_info[:example] = example_data.render(view_name)
              end
            end
          end
          # Save a full type example
          # ...but not for links or link classes (there's no object container context if done alone!!)
          unless( type < Praxis::Links ) #TODO: again, why is this special?
            type_output[:example] = if example_data.respond_to? :render
              example_data.render(:master)
            else
              example_data.dump
            end
          end

          # add an example for each attribute??
          File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(type_output))}
        end
      end
    end

    # index looks like something like this:
    #    {'1.0':
    #           {
    #           // Typical entry for controller with an associated mediatype
    #           "Post" : { media_type: "V1::MT:Post" , controller: "V1:Ctrl:Post"}
    #           // Unusual entry for controller without an associated mediatype
    #           "Admin" : { controller: "V1:Ctrl:Admin" }
    #           // Entry for mediatype that somehow is not associated with any controller...
    #           "RemoteMT" : { media_type: "V1:Ctrl:RemoteMT" }
    #           // Entry to a non-primitive type (but not a mediatype), that it is not covered by any related controller or mt
    #           "Locale" : { kind: "Module::Locale"}
    #           }
    #
    #    '2.0': {  ... }
    #    }
    def write_index( versioned_types )
      index = Hash.new
      media_types_seen_from_controllers = Set.new
      # Process the resources first

      @resources.each do |r|
        index[r.version] ||= Hash.new
        info = {controller: r.id}
        if r.media_type
          info[:media_type] = r.media_type.name
          media_types_seen_from_controllers << r.media_type
        end
        display_name  = r.id.split("::").last
        index[r.version][display_name] = info
      end

      versioned_types.each do |version, types|
        # Discard any mediatypes that we've already seen and processed as controller related
        reportable_types = types - media_types_seen_from_controllers - EXCLUDED_TYPES_FROM_TOP_LEVEL
        #TODO: think about these special cases, is it needed?
        reportable_types.reject!{|type| type < Praxis::Links || type < Praxis::MediaTypeCollection }

        reportable_types.each do |type|
          index[version] ||= Hash.new
          display_name = type.name.split("::").last + " (*)" #somehow this is just a MT so we probably wanna mark it different
          if index[version].has_key? display_name
            raise "Display name already taken for version #{version}! #{display_name}"
          end
          index[version][display_name] = if type < Praxis::MediaType
            {media_type: type.name }
          else
            {kind: type.name}
          end
        end
      end
      filename = File.join(@doc_root_dir, "index.json")
      dirname = File.dirname(filename)
      FileUtils.mkdir_p dirname unless File.exists? dirname
      File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(index))}
    end

    private

    def remove_previous_doc_data
      FileUtils.rm_rf @doc_root_dir if File.exists?(@doc_root_dir)
    end

  end
end
