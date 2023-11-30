ArchivesSpacePublic::Application.routes.draw do

    # Override handling of ARK URLs
    get '/*ark_tag:naan/:id' => 'arks#show', constraints: { ark_tag: 'ark:/' }

    # TODO: This doesn't work because there already is a route for xxx/yyy but it will after
    #       upgrading to a release containing https://github.com/archivesspace/archivesspace/pull/3043
    get '/*ark_tag:naan/:id' => 'arks#show', constraints: { ark_tag: 'ark:' }

end
