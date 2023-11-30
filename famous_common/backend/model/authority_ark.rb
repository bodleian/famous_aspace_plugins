class AuthorityArk < Sequel::Model(:authority_ark)

  include ASModel
  include FamousArks
  corresponds_to JSONModel(:authority_ark)
  set_model_scope :global


  def validate()

    # The constraint in the database would catch this, but testing here displays a friendlier message
    validates_unique([:ark], :message => "authority_ark_already_used")
    map_validation_to_json_property([:ark], :ark)

    super

  end


  def self.mint()

    ark_name = ArkNameCache.get_ark_name
    if !ark_name.nil?
      return AppConfig[:authority_ark_nma] + '/' + AppConfig[:ark_prefix] + AppConfig[:ark_naan] + '/' + ark_name
    else
      raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_mint_failure"]})
    end

  end


  def self.validate_arks(jsons)

    # Regex for validating Authority ARKs. Cannot be done in validate method above, as that is during storage, when ARKs have
    # already been reduced to just NAAN and ARK name
    @@authority_ark_regex ||= Regexp.compile(/^\s*#{Regexp.escape(AppConfig[:authority_ark_nma])}\/ark:\/?#{Regexp.escape(AppConfig[:ark_naan])}\/[A-Za-z0-9=~*+@_$.\/\-]+\s*$/)

    jsons.each_with_index do |json, index|

      if json['ark'].nil? or json['ark'].strip.empty?

        # This will trigger a new ARK to be minted, so it is OK

      elsif json['ark'] =~ @@authority_ark_regex

        reduced_ark = AuthorityArk.reduce_ark_for_storage(json['ark'])

        # Check this Authority ARK hasn't already been used as a Record ARK, as those also resolve
        if RecordArk.filter(:ark => reduced_ark).select_map(Sequel.function(:count, :id)).first > 0
          raise JSONModel::ValidationException.new(:errors => {"authority_arks/#{index}/ark" => ["authority_ark_same_as_record_ark"]})
        end

      else

        # The ARK is not a full URL, or uses the wrong NMA or NAAN, or has illegal characters in the ARK name
        raise JSONModel::ValidationException.new(:errors => {"authority_arks/#{index}/ark" => ["authority_ark_not_formatted_correctly"]})

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
      reduced_ark = AuthorityArk.reduce_ark_for_storage(json['ark'])

      # Store in database
      super(json, opts.merge(:ark => reduced_ark))

    end

  end


  def self.sequel_to_jsonmodel(objs, opts = {})

    # Build the basic JSON representation from the database
    jsons = super

    # Convert the NAAN and ARK Name, which is what is stored in the database, into a full URL ARK in the JSON
    jsons.zip(objs).each do |json, obj|
      json['ark'] = AppConfig[:authority_ark_nma] + '/' + AppConfig[:ark_prefix] + obj.ark
    end

    jsons
  end


end

