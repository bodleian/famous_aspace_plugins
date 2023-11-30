# Implements API endpoints for resolving Record ARKs and Authority ARKs (Object ARKs are not resolvable)

class ArchivesSpaceService < Sinatra::Base


  # Main resolver used by PUI. Looks up ARK in Solr. Returns one record URI (i.e. the path to the ArchivesSpace record.)
  # Record ARKs can be duplicated in a maximum of two records, so it will return the older of the two records.
  # Returns nothing if records are unpublished.

  Endpoint.get("/resolve_ark")
          .description("Resolve a record or authority ARK, returning the record URI")
          .params(["ark", String, "A full ARK or just the NAAN and ARK name, e.g. 12345/abcdef"])
          .permissions([:view_all_records])
          .returns([404, "Not found"],
                   [200, "OK"]) \
    do

      field_query = JSONModel.JSONModel(:field_query)
                             .from_hash('field' => 'arks_reduced_u_ustr',
                                        'value' => reduce_ark_for_searching(params[:ark]),
                                        'literal' => true)
                             .to_hash

      query = Solr::Query.create_advanced_search(JSONModel.JSONModel(:advanced_query).from_hash('query' => field_query))

      query.set_sort('create_time asc')

      query.pagination(1, 1).
        limit_fields_to(['uri']).
        show_published_only(true).
        show_suppressed(false)

      results = Solr.search(query)

      if results['total_hits'] == 0
        json_response([], 404)
      else
        json_response(results['results'][0]['uri'], 200)
      end

    end
  

  # Resolver used by the staff interface. Provides a list of (max 2) record URIs that the main resolver, above, could
  # return for Record ARKs. But uses the database instead of Solr, to avoid confusion if the indexer lagging behind.

  Endpoint.get("/resolve_record_ark_for_staff")
          .description("Get a list of records the specified ARK could potentially resolve to, in the order that they would")
          .params(["ark", String, "A full ARK or just the NAAN and ARK name, e.g. 12345/abcdef"])
          .permissions([])
          .returns([404, "Not found"],
                   [200, "OK"]) \
    do

      matching_record_ark_rows = RecordArk
        .filter(:ark => reduce_ark_for_searching(params[:ark]))
        .left_join(:resource, :resource__id => :record_ark__resource_id)
        .left_join(:archival_object, :archival_object__id => :record_ark__archival_object_id)
        .left_join(:repository, Sequel.function(:coalesce, :resource__repo_id, :archival_object__repo_id) => :repository__id)
        .select(
          Sequel.as(:record_ark__resource_id, :resource_id),
          Sequel.as(:record_ark__archival_object_id, :archival_object_id),
          Sequel.as(:repository__id, :repo_id),
          Sequel.as(:repository__publish, :repo_publish),
          Sequel.as(Sequel.function(:coalesce, :resource__create_time, :archival_object__create_time), :create_time),
          Sequel.as(Sequel.function(:coalesce, :resource__publish, :archival_object__publish), :publish),
          Sequel.as(Sequel.function(:coalesce, :resource__suppressed, :archival_object__suppressed), :suppressed),
        )

      if matching_record_ark_rows.count == 0
        json_response([], 404)
      else

        returnarray = []
        matching_record_ark_rows.each do |row|
          published = (int2bool(row[:publish]) && !int2bool(row[:suppressed]) && int2bool(row[:repo_publish]))
          if !row[:resource_id].nil?
            returnarray << {
              'uri' => "/repositories/#{row[:repo_id]}/resources/#{row[:resource_id]}",
              'repo_id' => row[:repo_id],
              'published' => published,
              'create_time' => row[:create_time],
            }
          else
            if published
              published = !ArchivalObject.calculate_has_unpublished_ancestor(ArchivalObject[row[:archival_object_id]], true)
            end
            returnarray << {
              'uri' => "/repositories/#{row[:repo_id]}/archival_objects/#{row[:archival_object_id]}",
              'repo_id' => row[:repo_id],
              'published' => published,
              'create_time' => row[:create_time],
            }
          end
        end
      end

      json_response(returnarray.sort_by{ |h| h['create_time'] }, 200)

    end


  def reduce_ark_for_searching(arkstr)

    # Reduces any ARK to just the NAAN and the ARK name (e.g. "12345/abcdef") as that is what is stored in the database
    # and indexed in the arks_reduced_u_ustr Solr field. Also remove hyphens which, while valid in ARKs, are "identity inert".
    return arkstr.partition(/ark:\/?/).reject{ |c| c.empty? }.last.tr('-', '').strip

  end


  def int2bool(rowval)
    # Booleans are stored in the database as integers of value either 0 or 1
    return (rowval == 1)
  end


end