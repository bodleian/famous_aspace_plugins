# This adds extra serialization steps into the EAD 2002 and EAD3 exporters, to output ARKs.


class RecordArkSerialize

  # Add unitids for each Record ARK (EAD 2002 version)
  def call(data, xml, fragments, context)
    if context == :did and data.record_arks.is_a?(Array)
      data.record_arks.each { |record_ark|
        xml.unitid ({ 'type' => 'ARK', 'label' => 'Record ARK' }) { xml.text record_ark['ark'] }
      }
    end
  end

end


class ObjectArkSerialize

  # Add unitids for each Object ARK (EAD 2002 version)
  def call(data, xml, fragments, context)
    if context == :did and data.object_arks.is_a?(Array)
      data.object_arks.each { |object_ark|
        xml.unitid ({ 'type' => 'ARK', 'label' => 'Object ARK' }) { xml.text object_ark['ark'] }
      }
    end
  end

end


class AuthorityArkSerialize

  # Add extptrs for each Authority ARK (EAD 2002 version)
  def call(data, xml, fragments, context)
    if [:persname, :famname, :corpname, :subject, :geogname, :genreform, :occupation, :function].include?(context)
      if data['authority_arks'].is_a?(Array)
        data['authority_arks'].each { |authority_ark|
          xml.extptr ({ 'xlink:href' => authority_ark['ark'] }) { }
        }
      end
    end
  end

end


class RecordArkSerializeEad3

  # Add unitids for each Record ARK (EAD3 version)
  def call(data, xml, fragments, context)
    if context == :did and data.record_arks.is_a?(Array)
      data.record_arks.each { |record_ark|
        xml.unitid ({ 'localtype' => 'ARK', 'label' => 'Record ARK' }) { xml.text record_ark['ark'] }
      }
    end
  end

end


class ObjectArkSerializeEad3

  # Add unitids for each Object ARK (EAD3 version)
  def call(data, xml, fragments, context)
    if context == :did and data.object_arks.is_a?(Array)
      data.object_arks.each { |object_ark|
        xml.unitid ({ 'localtype' => 'ARK', 'label' => 'Object ARK' }) { xml.text object_ark['ark'] }
      }
    end
  end

end


class AuthorityArkSerializeEad3

  # Add ptrs for each Authority ARK (EAD3 version)
  def call(data, xml, fragments, context)
    if [:persname, :famname, :corpname, :subject, :geogname, :genreform, :occupation, :function].include?(context)
      if data['authority_arks'].is_a?(Array)
        data['authority_arks'].each { |authority_ark|
          xml.ptr ({ 'href' => authority_ark['ark'] }) { }
        }
      end
    end
  end

end


# TODO: Everything below this comment override core methods to allow the hooks above (specifically the ones for Authority ARKs) to work.
#       They can be deleted after upgrading to a release containing https://github.com/archivesspace/archivesspace/pull/3047


class EADSerializer < ASpaceExport::Serializer

  def serialize_origination(data, xml, fragments)
    unless data.creators_and_sources.nil?
      data.creators_and_sources.each do |link|
        agent = link['_resolved']
        published = agent['publish'] === true

        next if !published && !@include_unpublished

        link['role'] == 'creator' ? role = link['role'].capitalize : role = link['role']
        relator = link['relator']
        sort_name = agent['display_name']['sort_name']
        rules = agent['display_name']['rules']
        source = agent['display_name']['source']
        authfilenumber = agent['display_name']['authority_id']
        node_name = case agent['agent_type']
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    when 'agent_software'; 'name'
                    end

        origination_attrs = {:label => role}
        origination_attrs[:audience] = 'internal' unless published
        xml.origination(origination_attrs) {
          atts = {:role => relator, :source => source, :rules => rules, :authfilenumber => authfilenumber}
          atts.reject! {|k, v| v.nil?}

          xml.send(node_name, atts) {
            sanitize_mixed_content(sort_name, xml, fragments )
            EADSerializer.run_serialize_step(agent, xml, fragments, node_name.to_sym)
          }
        }
      end
    end
  end

  def serialize_controlaccess(data, xml, fragments)
    if (data.controlaccess_subjects.length + data.controlaccess_linked_agents(@include_unpublished).reject {|x| x.empty?}.length) > 0
      xml.controlaccess {
        data.controlaccess_subjects.zip(data.subjects).each do |node_data, subject|
          xml.send(node_data[:node_name], node_data[:atts]) {
            sanitize_mixed_content( node_data[:content], xml, fragments, ASpaceExport::Utils.include_p?(node_data[:node_name]) )
            EADSerializer.run_serialize_step(subject['_resolved'], xml, fragments, node_data[:node_name].to_sym)
          }
        end

        data.controlaccess_linked_agents(@include_unpublished).zip(data.linked_agents).each do |node_data, agent|
          next if node_data.empty?
          xml.send(node_data[:node_name], node_data[:atts]) {
            sanitize_mixed_content( node_data[:content], xml, fragments, ASpaceExport::Utils.include_p?(node_data[:node_name]) )
            EADSerializer.run_serialize_step(agent['_resolved'], xml, fragments, node_data[:node_name].to_sym)
          }
        end
      } #</controlaccess>
    end
  end

end


class EAD3Serializer < EADSerializer

  def serialize_origination(data, xml, fragments)
    unless data.creators_and_sources.nil?
      data.creators_and_sources.each do |link|
        agent = link['_resolved']
        link['role'] == 'creator' ? role = link['role'].capitalize : role = link['role']
        relator = link['relator']
        sort_name = agent['display_name']['sort_name']
        rules = agent['display_name']['rules']
        source = agent['display_name']['source']
        authfilenumber = agent['display_name']['authority_id']
        node_name = case agent['agent_type']
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    when 'agent_software'; 'name'
                    end
        xml.origination(:label => role) {

          atts = {:relator => relator, :source => source, :rules => rules, :identifier => authfilenumber}

          atts.reject! {|k, v| v.nil?}

          xml.send(node_name, atts) {
            xml.part() {
              sanitize_mixed_content(sort_name, xml, fragments )
              EAD3Serializer.run_serialize_step(agent, xml, fragments, node_name.to_sym)
            }
          }
        }
      end
    end
  end

  def serialize_controlaccess(data, xml, fragments)
    if (data.controlaccess_subjects.length + data.controlaccess_linked_agents(@include_unpublished).reject {|x| x.empty?}.length) > 0
      xml.controlaccess {

        data.controlaccess_subjects.zip(data.subjects).each do |node_data, subject|

          if node_data[:atts]['authfilenumber']
            node_data[:atts]['identifier'] = node_data[:atts]['authfilenumber'].clone
            node_data[:atts].delete('authfilenumber')
          end

          xml.send(node_data[:node_name], node_data[:atts]) {
            xml.part() {
              sanitize_mixed_content( node_data[:content], xml, fragments, ASpaceExport::Utils.include_p?(node_data[:node_name]) )
              EAD3Serializer.run_serialize_step(subject['_resolved'], xml, fragments, node_data[:node_name].to_sym)
            }
          }
        end

        data.controlaccess_linked_agents(@include_unpublished).zip(data.linked_agents).each do |node_data, agent|

          next if node_data.empty?

          if node_data[:atts][:role]
            node_data[:atts][:relator] = node_data[:atts][:role]
            node_data[:atts].delete(:role)
          end

          if node_data[:atts][:authfilenumber]
            node_data[:atts][:identifier] = node_data[:atts][:authfilenumber].clone
            node_data[:atts].delete(:authfilenumber)
          end

          xml.send(node_data[:node_name], node_data[:atts]) {
            xml.part() {
              sanitize_mixed_content( node_data[:content], xml, fragments, ASpaceExport::Utils.include_p?(node_data[:node_name]) )
              EAD3Serializer.run_serialize_step(agent['_resolved'], xml, fragments, node_data[:node_name].to_sym)
            }
          }
        end

      } #</controlaccess>
    end
  end

end


ASpaceExport::ArchivalObjectDescriptionHelpers.module_eval do

  def controlaccess_linked_agents(include_unpublished = false)
    unless @controlaccess_linked_agents
      results = []
      linked = self.linked_agents || []
      linked.each_with_index do |link, i|
        if link['role'] == 'creator' || (link['_resolved']['publish'] == false && !include_unpublished)
          results << {}
          next
        end
        role = link['relator'] ? link['relator'] : (link['role'] == 'source' ? 'fmo' : nil)

        agent = link['_resolved'].dup
        sort_name = agent['display_name']['sort_name']
        rules = agent['display_name']['rules']
        source = agent['display_name']['source']
        authfilenumber = agent['display_name']['authority_id']
        content = sort_name.dup

        if link['terms'].length > 0
          content << " -- "
          content << link['terms'].map {|t| t['term']}.join(' -- ')
        end

        node_name = case agent['agent_type']
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    when 'agent_software'; 'name'
                    end

        atts = {}
        atts[:role] = role if role
        atts[:source] = source if source
        atts[:rules] = rules if rules
        atts[:authfilenumber] = authfilenumber if authfilenumber
        atts[:audience] = 'internal' if link['_resolved']['publish'] == false

        results << {:node_name => node_name, :atts => atts, :content => content}
      end

      @controlaccess_linked_agents = results
    end

    @controlaccess_linked_agents
  end

end