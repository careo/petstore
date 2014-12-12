module Swagger
  class Definitions
    attr_reader :types
    
    def initialize( types: types )
      @types = types
    end
    def generate
      definitions = {}
      types.each do |type|
        next if Type::EXCLUDED_TYPES_FROM_TOP_LEVEL.include?(type)
        name = type.name

        definitions[name] = Type.stuff(type)
      end
      definitions
    end
  end
end