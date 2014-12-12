class Pet < Praxis::MediaType
  identifier 'application/vnd.rightswagger.pet'

  attributes do
    attribute :id, Integer, required: true
    attribute :name, String, required: true
    attribute :tag, String
  end

  view :default do
    attribute :id
    attribute :name
    attribute :tag
  end
  
end