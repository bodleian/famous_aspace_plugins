class RecordArk < Sequel::Model(:record_ark)

  include ASModel
  include FamousArks
  corresponds_to JSONModel(:record_ark)
  set_model_scope :global


  def validate()

    # The constraint in the database would catch this, but testing here displays a friendlier message
    validates_unique([:ark, :prime], :message => "record_ark_already_used_twice")
    map_validation_to_json_property([:ark, :prime], :ark)

    super

  end


  def self.mint()

    ark_name = ArkNameCache.get_ark_name
    if !ark_name.nil?
      return AppConfig[:record_ark_nma] + '/' + AppConfig[:ark_prefix] + AppConfig[:ark_naan] + '/' + ark_name
    else
      raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_mint_failure"]})
    end

  end


  def self.validate_arks(jsons, resource_id, archival_object_id)

    # Regex for validating Record ARKs. Cannot be done in validate method above, as that is during storage, when ARKs have
    # already been reduced to just NAAN and ARK name
    @@record_ark_regex ||= Regexp.compile(/^\s*#{Regexp.escape(AppConfig[:record_ark_nma])}\/ark:\/?#{Regexp.escape(AppConfig[:ark_naan])}\/[A-Za-z0-9=~*+@_$.\/\-]+\s*$/)

    jsons.each_with_index do |json, index|

      if json['ark'].nil? or json['ark'].strip.empty?

        # This will trigger a new ARK to be minted, so it is OK

      elsif json['ark'] =~ @@record_ark_regex

        reduced_ark = RecordArk.reduce_ark_for_storage(json['ark'])

        # Looks like a valid full ARK, so check there aren't already two other records with the same Record ARK
        if !resource_id.nil?
          existing_record_arks = RecordArk.filter(:ark => reduced_ark).exclude(:resource_id => resource_id).select_map(:id)
        elsif !archival_object_id.nil?
          existing_record_arks = RecordArk.filter(:ark => reduced_ark).exclude(:archival_object_id => archival_object_id).select_map(:id)
        else
          existing_record_arks = RecordArk.filter(:ark => reduced_ark).select_map(:id)
        end
        if existing_record_arks.count > 1
          raise JSONModel::ValidationException.new(:errors => {"record_arks/#{index}/ark" => ["record_ark_already_used_twice"]})
        end

        # Check this Record ARK hasn't already been used as an Authority ARK, as those also resolve
        if AuthorityArk.filter(:ark => reduced_ark).select_map(Sequel.function(:count, :id)).first > 0
          raise JSONModel::ValidationException.new(:errors => {"record_arks/#{index}/ark" => ["record_ark_same_as_authority_ark"]})
        end

      else

        # The ARK is not a full URL, or uses the wrong NMA or NAAN, or has illegal characters in the ARK name
        raise JSONModel::ValidationException.new(:errors => {"record_arks/#{index}/ark" => ["record_ark_not_formatted_correctly"]})

      end
    end

  end


  def self.create_from_json(json, opts = {})

    # Read the JSON sent from the staff interface (or other API user)
    if json['ark'].nil? or json['ark'].strip.empty?

      # No ARK has been specified, so generate a new one, and store in database
      super(json, opts.merge(:ark => mint_for_storage))

    else

      # Convert full URL ARKs in JSON to just NAAN and ARK Name for storage in the database
      reduced_ark = RecordArk.reduce_ark_for_storage(json['ark'])

      if existing_record_arks = RecordArk.filter(:ark => reduced_ark).select_map(:prime)
        if existing_record_arks.count == 1
          # There is another record with the same ARK
          if existing_record_arks.first == 1
            json['prime'] = false
          else
            json['prime'] = true
          end
        end
      end

      # Store in database
      super(json, opts.merge(:ark => reduced_ark))

    end

  end


  def self.sequel_to_jsonmodel(objs, opts = {})

    # Retrieve from the database and convert to JSON
    jsons = super

    # Convert the NAAN and ARK Name stored in the database to a full URL ARK in the JSON
    jsons.zip(objs).each do |json, obj|
      json['ark'] = AppConfig[:record_ark_nma] + '/' + AppConfig[:ark_prefix] + obj.ark
    end

    jsons
  end


end

