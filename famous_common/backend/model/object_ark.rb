class ObjectArk < Sequel::Model(:object_ark)

  include ASModel
  include FamousArks
  corresponds_to JSONModel(:object_ark)
  set_model_scope :global


  def self.mint()

    ark_name = ArkNameCache.get_ark_name
    if !ark_name.nil?
      return AppConfig[:object_ark_nma] + '/' + AppConfig[:ark_prefix] + AppConfig[:ark_naan] + '/' + ark_name
    else
      raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_mint_failure"]})
    end

  end


  def self.validate_arks(jsons)

    # Regex for validating Object ARKs. Cannot be done in validate method above, as that is during storage, when ARKs have
    # already been reduced to just NAAN and ARK name
    @@object_ark_regex ||= Regexp.compile(/^\s*#{Regexp.escape(AppConfig[:object_ark_nma])}\/ark:\/?#{Regexp.escape(AppConfig[:ark_naan])}\/[A-Za-z0-9=~*+@_$.\/\-]+\s*$/)

    jsons.each_with_index do |json, index|

      unless json['ark'].nil? or json['ark'].strip.empty? or json['ark'] =~ @@object_ark_regex

        # The ARK is not a full URL, or uses the wrong NMA or NAAN, or has illegal characters in the ARK name
        raise JSONModel::ValidationException.new(:errors => {"object_arks/#{index}/ark" => ["object_ark_not_formatted_correctly"]})

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

      # Store in database
      super(json, opts.merge(:ark => reduced_ark))

    end

  end


  def self.sequel_to_jsonmodel(objs, opts = {})

    # Build the basic JSON representation from the database
    jsons = super

    # Convert the NAAN and ARK Name, which is what is stored in the database, into a full URL ARK in the JSON
    jsons.zip(objs).each do |json, obj|
      json['ark'] = AppConfig[:object_ark_nma] + '/' + AppConfig[:ark_prefix] + obj.ark
    end

    jsons

  end


end

