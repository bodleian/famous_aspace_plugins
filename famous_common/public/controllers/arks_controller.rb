class ArksController < ApplicationController


  def show

    # Read requested path
    arktofind = params[:naan] + '/' + params[:id]

    # TODO: Strip off sub-parts and/or variants?

    # Lookup ARK via HTTP request to this plug-in's custom backend endpoint,
    # to resolve the ARK and return the corresponding record URI
    json_response = archives_space_client.send_ark_request(arktofind)

    # Redirect to record URI, if one has been found
    if json_response.length == 0
      render 'shared/not_found', :status => 404
    else
      redirect_to(json_response, status: 302)
    end

  end


  def archives_space_client
    ArchivesSpaceClient.instance
  end


  # TODO: Instead of redirecting, replicate the controller code in core ArchivesSpace or, more sustainably in the
  #       long term, change core ArchivesSpace to encapsulate the bits needed in separate methods that can be called here.


end
