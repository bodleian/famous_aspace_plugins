Resource.include(RecordArks)
Resource.include(ObjectArks)

Resource.class_eval do

  include FamousArks

  class << self


    # Alias the class methods that will be overridden below
    alias_method :core_create_from_json, :create_from_json


    def create_from_json(json, extra_values = {})

      # Add a Record ARK if the new record lacks one.
      # This represents the record rather than the object it describes.
      if json['record_arks'].length == 0
        json['record_arks'] << { 'ark' => RecordArk.mint }
      else

        # Validate the Record ARKs. Do it here so invalid ARKs can be highlighted in the staff interface.
        RecordArk.validate_arks(json['record_arks'], nil, nil)

      end

      # Add an Object ARK if the new record lacks one, and it is at an appropriate level.
      # This represents the object rather than the record describing it.
      if json['object_arks'].length == 0
        if AppConfig[:object_ark_automint_levels].include?(json['level'])
          json['object_arks'] << { 'ark' => ObjectArk.mint }
        elsif !json['other_level'].nil? and AppConfig[:object_ark_automint_levels].include?(json['other_level'].downcase)
          json['object_arks'] << { 'ark' => ObjectArk.mint }
        end

      else

        # Validate the Object ARKs. Do it here so invalid ARKs can be highlighted in the staff interface.
        ObjectArk.validate_arks(json['object_arks'])

      end

      # Store the new record
      core_create_from_json(json, extra_values)

    end


  end


  # Alias the instance methods that will be overridden below
  alias_method :core_update_from_json, :update_from_json
  alias_method :core_delete, :delete
  alias_method :core_assimilate, :assimilate


  def update_from_json(json, extra_values = {}, apply_nested_records = true)

    # Validate all the ARKs. Do it here so invalid ARKs can be highlighted in the staff interface.
    RecordArk.validate_arks(json['record_arks'], self.id, nil)
    ObjectArk.validate_arks(json['object_arks'])

    if json['record_arks'].length == 0
      # If the user has deleted all previous Record ARKs then add a new one.
      # All records must have one, as it represents the record and provides its permalink.
      json['record_arks'] << { 'ark' => RecordArk.mint }
    end

    # If the user has deleted all previous Object ARKs, and it is at an appropriate level, add a new one.
    if json['object_arks'].length == 0
      if AppConfig[:object_ark_automint_levels].include?(json['level'])
        json['object_arks'] << { 'ark' => ObjectArk.mint }
      elsif !json['other_level'].nil? and AppConfig[:object_ark_automint_levels].include?(json['other_level'].downcase)
        json['object_arks'] << { 'ark' => ObjectArk.mint }
      end
    end

    # Update the record in the database
    return core_update_from_json(json, extra_values, apply_nested_records)

  end


  def assimilate(victims)

    # Transfer Record ARKs when merging resources
    begin
      victims.reject {|v| (v.class == self.class) && (v.id == self.id)}.each do |victim|
        RecordArk.filter(:resource_id => victim.id).update(:resource_id => self.id, :system_mtime => Time.now)
      end
    rescue Sequel::DatabaseError
      raise ConflictException.new("Cannot update record_ark table")
    end

    # Transfer Object ARKs when merging resources
    begin
      victims.reject {|v| (v.class == self.class) && (v.id == self.id)}.each do |victim|
        ObjectArk.filter(:resource_id => victim.id).update(:resource_id => self.id, :system_mtime => Time.now)
      end
    rescue Sequel::DatabaseError
      raise ConflictException.new("Cannot update object_ark table")
    end

    # Do the merger
    core_assimilate(victims)

  end


end
