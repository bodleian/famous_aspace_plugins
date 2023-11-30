# Enable the redirections in routes.rb
Plugins::extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))


Rails.application.config.after_initialize do


  class ArchivesSpaceClient


    # Add a method to the public service's backend client for accessing the backend ARK resolver.
    # Doing it this way means the backend will know it is the public_anonymous user, so won't try
    # to resolve unpublished records.
    def send_ark_request(ark)
      url = URI("#{JSONModel::HTTP.backend_url}/resolve_ark?ark=#{ark}")
      request = Net::HTTP::Get.new(url)
      response = do_http_request(request)
      if response
        return JSON.parse(response.body)
      else
        return {}
      end
    end


  end


end
