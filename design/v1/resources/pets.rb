
class Pets
  include Praxis::ResourceDefinition

  version '1.0.0', using: :path

  media_type Pet


  routing do
    prefix '/pets'
  end


  action :findPets do
    description 'Returns all pets from the system that the user has access to'

    routing do
      get ''
    end

    params do
      attribute :tags,
        Attributor::CSV.of(String),
        description: 'tags to filter by'
      attribute :limit, Integer,
        description: 'maximum number of results to return'
    end

    response :pets
  end


  action :addPet do
    description 'Creates a new pet in the store.  Duplicates are allowed'
    routing do
      post ''
    end

    payload do
      attribute :pet, description: 'Pet to add to the store', reference: Pet, required: true do
        attribute :id, required: false
        attribute :name, required: true
      end
    end

    response :pet

  end


  action :findPetById do
    description 'Returns a user based on a single ID, if the user does not have access to the pet'
    routing do
      get '/:id'
    end

    params do
      attribute :id, required: true,
        description: 'ID of pet to fetch'
    end

    response :pet
  end


  action :deletePet do
    description 'deletes a single pet based on the ID supplied'
    routing do
      delete '/:id'
    end

    params do
      attribute :id, required: true,
        description: 'ID of pet to delete'
    end

    response :deleted, description: 'pet deleted'
  end
end
