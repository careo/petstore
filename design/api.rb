Praxis::ApiDefinition.define do
  response_template :pets do
    status 200
    media_type PetCollection
    description 'pet response'
  end

  response_template :pet do
    status 200
    media_type Pet
    #header 'X-Foo'
    #header 'X-Bar' => 'value'
    #header 'X-Thing' => /thing/
    description 'pet response'
  end

  response_template :deleted do |description: 'deleted'|
    status 204
    description description
  end

end


class Praxis::Request
  def self.path_version_prefix
    "/api/v".freeze
  end

end
