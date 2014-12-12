module Controllers
  class Pets
    include Praxis::Controller

    implements ::Pets

    def findPets(tags:[], limit:nil)
      self.response = Responses::Pets.new

      pet = Pet.example.render
      return JSON.pretty_generate([pet])
    end

  end

end

