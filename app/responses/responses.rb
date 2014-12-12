module Responses
  class Pet < Praxis::Responses::Ok
    def handle
      self.headers['Content-Type'] = 'application/vnd.rightswagger.pet'
    end

  end

  class Pets < Praxis::Responses::Ok
    def handle
      self.headers['Content-Type'] = 'application/vnd.rightswagger.pet-collection'
    end

  end

end
