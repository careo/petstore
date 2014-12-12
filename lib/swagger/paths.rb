module Swagger
  class Paths
    attr_reader :resources
    def initialize( resources: resources )
      @resources = resources
    end
    
    def generate
      paths = {}
      resources.each do |resource|
        resource.controller_config.actions.each do |name, action_config|

          action_config.routes.each do |route|
            data = Action.new(config: action_config, params_in_path: route.path.named_captures.keys).generate

            path = route.path.to_templates.first
            verb = route.verb.downcase
            paths[path] ||= {}
            paths[path][verb] = data
            # TODO: there could be a paths[path][:parameters] => that are common to all actions....
          end
        end
      end
      paths
    end
  
  end
end