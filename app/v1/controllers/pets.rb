module Controllers
  class Pets
    include Praxis::Controller

    implements ::Pets

    def findPets(tags:[], limit:nil)
      puts "Findind all pets (tags: #{tags}, limit: #{limit})"
      self.response = Responses::Pets.new

      pet = Pet.example.render
      return JSON.pretty_generate([pet])
    end

    def findPetById(id:)
      puts "Finding Pet with id: #{id}"
      self.response = Responses::Pet.new

      pet = Pet.example.render
      pet[:id] = id
      return JSON.pretty_generate(pet)
    end
    
    def addPet(*args)
      puts "Adding Pet:  #{request.payload.dump}"
      return Responses::Pet.new
    end

    def deletePet(id:)
      puts "Deleting Pet with id: #{id}"
      return Praxis::Responses::Deleted.new
    end
  end

end

