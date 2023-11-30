class IndexerCommon


  # Hooks to index ARKs in two Solr fields:
  #  - arks_reduced_u_ustr
  #    - for resolving ARKs
  #    - doesn't include Object ARKs
  #    - only contains the NAAN and ARK name
  #    - not stored
  #  - arks_full_u_sstr
  #    - for searching in the staff interface
  #    - includes all ARKs
  #    - in full URL form
  #    - stored
  # Both are string-type fields (i.e. not tokenized, so only exact matches will be returned.)
  # Both are multi-valued, because records can have multiple ARKs of the same type.


  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook do |doc, record|

      if record['record']['record_arks'].is_a?(Array)
        doc['arks_reduced_u_ustr'] ||= []
        doc['arks_full_u_sstr'] ||= []
        record['record']['record_arks'].each { |record_ark|
          doc['arks_reduced_u_ustr'].push(self.reduce_ark_for_indexing(record_ark['ark']))
          doc['arks_full_u_sstr'].push(record_ark['ark'])
        }
        
      elsif record['record']['authority_arks'].is_a?(Array)
        doc['arks_reduced_u_ustr'] ||= []
        doc['arks_full_u_sstr'] ||= []
        record['record']['authority_arks'].each { |authority_ark|
          doc['arks_reduced_u_ustr'].push(self.reduce_ark_for_indexing(authority_ark['ark']))
          doc['arks_full_u_sstr'].push(authority_ark['ark'])
        }
      end

      if record['record']['object_arks'].is_a?(Array)
        doc['arks_full_u_sstr'] ||= []
        record['record']['object_arks'].each { |object_ark|
          doc['arks_full_u_sstr'].push(object_ark['ark'])
        }
      end

    end

  end


  def self.reduce_ark_for_indexing(arkstr)

    # Convert full URL ARKs to just the NAAN and the ARK name
    return arkstr.partition(/ark:\/?/).reject{ |c| c.empty? }.last.tr('-','').strip

  end


end