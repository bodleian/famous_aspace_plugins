# Overrides the configure method in the EADConverter class, so that reading unitids with a type attribute of "ARK" can
# be customized. These changes will also apply to alternative importers created by subclassing EADConverter. Does not
# do anything to try to import Authority ARKs (exported as extptr/ptr) because the importer matches to existing agents
# and subjects using the text of the subject, persname, etc.

# TODO: Currently ignores label attributes - should it throw an error?
# TODO: Currently skips any ARK without the specified NMAs for Record and Object ARKs - should it throw an error?
# TODO: Allow different NAANs for each repository? If so, use RequestContext.get(:repo_id) to vary the regex.

class EADConverter < Converter

  class << self


    # Alias the class methods that will be overridden below
    alias_method :core_configure, :configure


    def configure

      # Retain all the core handlers for EAD elements other than unitid
      core_configure

      # Define regex patterns for matching different ARK types (done here so that
      # normalization of NMAs run by plugin_init.rb has taken effect.)
      @@record_ark_regex ||= Regexp.compile(/^#{Regexp.escape(AppConfig[:record_ark_nma])}\/ark:\/?#{Regexp.escape(AppConfig[:ark_naan])}\/[A-Za-z0-9=~*+@_$.\/\-]+$/)
      @@object_ark_regex ||= Regexp.compile(/^#{Regexp.escape(AppConfig[:object_ark_nma])}\/ark:\/?#{Regexp.escape(AppConfig[:ark_naan])}\/[A-Za-z0-9=~*+@_$.\/\-]+$/)

      # Override the handler for unitid elements
      with 'unitid' do |node|

        # Handle unitids containing ARKs differently
        is_ark = false
        if (!node.attribute('type').nil? && node.attribute('type').upcase == 'ARK') || (!node.attribute('localtype').nil? && node.attribute('localtype').upcase == 'ARK')
          inner_xml_stripped = inner_xml.strip
          if inner_xml_stripped =~ @@record_ark_regex
            # This is a Record ARK
            is_ark = true
            ancestor(:resource, :archival_object) do |obj|
              make :record_ark, {
                :ark => inner_xml_stripped
              } do |record_ark|
                set ancestor(:resource, :archival_object), :record_arks, record_ark
              end
            end
          elsif inner_xml_stripped =~ @@object_ark_regex
            # This is an Object ARK
            is_ark = true
            ancestor(:resource, :archival_object) do |obj|
              make :object_ark, {
                :ark => inner_xml_stripped
              } do |object_ark|
                set ancestor(:resource, :archival_object), :object_arks, object_ark
              end
            end
          end
        end

        unless is_ark
          # Below is a copy of the core ArchivesSpace unitid handler in ead_converter.rb, but without any of
          # their ARK-handling code, which doesn't meet requirements for Bodleian ARK usage. This will import
          # non-ARK unitids.
          # TODO: Review this when upgrading to new ArchivesSpace releases (last checked against v3.4.1)
          ancestor(:note_multipart, :resource, :archival_object) do |obj|
            case obj.class.record_type
            when 'resource'
              set obj, :id_0, inner_xml if obj.id_0.nil? || obj.id_0.empty?
              if node.attribute( "type")
                make :external_id, {
                  :source => node.attribute( "type"),
                  :external_id => inner_xml
                } do |ext_id|
                  set ancestor(:resource ), :external_ids, ext_id
                end
              end
            when 'archival_object'
              set obj, :component_id, inner_xml if obj.component_id.nil? || obj.component_id.empty?
              if node.attribute( "type" )
                make :external_id, {
                  :source => node.attribute( "type" ),
                  :external_id => inner_xml
                } do |ext_id|
                  set ancestor(:resource, :archival_object), :external_ids, ext_id
                end
              end
            end
          end
          # End of copy of core unitid handler
        end

      end

    end


  end

end