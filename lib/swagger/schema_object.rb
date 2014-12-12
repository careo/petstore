module Swagger
  # these can be: primitive object, an array or an object. From swagger spec:
  # The Schema Object allows the definition of input and output data types. 
  # These types can be objects, but also primitives and arrays. This object is based on 
  # the JSON Schema Specification Draft 4 and uses a predefined subset of it. 
  # On top of this subset, there are extensions provided by this specification to allow 
  # for more complete documentation.
  
  # JSON schema fields, identically supported:
  # 
  # $ref
  # format (See Data Type Formats for further details)
  # title
  # description (GFM syntax can be used for rich text representation)
  # default
  # multipleOf
  # maximum
  # exclusiveMaximum
  # minimum
  # exclusiveMinimum
  # maxLength
  # minLength
  # pattern
  # maxItems
  # minItems
  # uniqueItems
  # maxProperties
  # minProperties
  # required
  # enum
  # type
  
  # JSON schema fields, supported but slightly differently
  # items
  # allOf
  # properties
  
  # New (extended) fields that do not exist in JSON schema
  # discriminator --  string	Adds support for polymorphism. The discriminator is the schema property name that is used to differentiate between other schemas that inherit this schema. The property name used MUST be defined at this schema and it MUST be in the required property list. When used, the value MUST be the name of this schema or any schema that inherits it.
  # readOnly      --  boolean	Relevant only for Schema "properties" definitions. Declares the property as "read only". This means that it MAY be sent as part of a response but MUST NOT be sent as part of the request. Properties marked as readOnly being true SHOULD NOT be in the required list of the defined schema. Default value is false.
  # xml           --  XML Object	This MAY be used only on properties schemas. It has no effect on root schemas. Adds Additional metadata to describe the XML representation format of this property.
  # externalDocs  --  External Documentation Object	Additional external documentation for this schema.
  # example       --  Object	A free-form property to include a an example of an instance for this schema.
  class SchemaObject
    
  end
end
    