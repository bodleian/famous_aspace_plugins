# Add search field for ARKs to staff interface advanced search form
# TODO: This doesn't work because core ArchivesSpace converts colons to spaces before sending to Solr.
#       It can be uncommented after upgrading to a release containing https://github.com/archivesspace/archivesspace/pull/3057
# AdvancedSearch.define_field(
#   :name => 'arks_full_u_sstr',
#   :type => :text,
#   :visibility => [:staff],
#   :solr_field => 'arks_full_u_sstr',
#   :always_literal => true,
#   )
