module Swagger
  class Type
    
    # Translate a praxis type to a primitive swagger type (or bail if it is not)
    def self.name_for( praxis_type )
      name = case praxis_type
        when Attributor::Boolean
          'boolean'.freeze
        when Attributor::Integer, Attributor::BigNum
          'integer'.freeze
        when Attributor::Float, Attributor::BigDecimal
          'number'.freeze
        when Attributor::String
          'string'.freeze
        when Attributor::Date, Attributor::DateTime
          'string'.freeze
        else
          raise "Ooops...do not know how to map type: #{praxis_type} to any of the basic swagger types...is this a collection or an object?"
        end
        name
    end
    
    EXCLUDED_TYPES_FROM_TOP_LEVEL = Set.new( [Attributor::Boolean, Attributor::CSV, Attributor::DateTime, Attributor::Float, Attributor::Hash, Attributor::Ids, Attributor::Integer, Attributor::Object,  Attributor::String ] ).freeze
    
    def self.for(attribute)
      
      if attribute.kind_of? Attributor::Attribute
        type = attribute.type
      else
        type = attribute
      end
      
      # TODO: we should detect if, the type needs to be "inlined" here with an 'array' type or 'schema'
      # ...or instead we need to use a $ref to an already defined one.
      if type == Attributor::Integer
        return {type: 'integer', format: 'int32'}
      elsif type == Attributor::String
        return {type: 'string'}
      elsif type.ancestors.include?(Attributor::Collection)
        val = {type: 'array', items: Type.for(type.member_attribute.type)}
        if type.ancestors.include?(Attributor::CSV)
          val[:collectionFormat] = 'csv'
        end
        return val
      elsif type.attributes.any?
        return {schema: Type.stuff(type) } 
      else
        binding.pry
        raise "unknown type: #{type.inspect}"
      end
    end
    
    def self.stuff(type)
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
          properties[name] = Type.for(attribute)
        end

        val = {properties: properties}
        if required.any?
          val[:required] = required
        end
        val
      end
    end
  end
  
end