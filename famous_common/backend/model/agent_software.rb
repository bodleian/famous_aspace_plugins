AgentSoftware.include(AuthorityArks)

AgentSoftware.class_eval do


  class << self


    # Alias the class methods that will be overridden below
    alias_method :core_create_from_json, :create_from_json


    def create_from_json(json, extra_values = {})

      # Add an Authority ARK if the new record lacks one.
      if json['authority_arks'].length == 0
        json['authority_arks'] << { 'ark' => AuthorityArk.mint }

      else

        # Validate the ARKs. Do it here so invalid ARKs can be highlighted in the staff interface.
        AuthorityArk.validate_arks(json['authority_arks'])

      end

      # Store the new record
      core_create_from_json(json, extra_values)

    end

  end


  # Alias the instance methods that will be overridden below
  alias_method :core_update_from_json, :update_from_json
  alias_method :core_assimilate, :assimilate


  def update_from_json(json, extra_values = {}, apply_nested_records = true)

    # If the user has deleted all previous Authority ARKs, add a new one.
    if json['authority_arks'].length == 0
      json['authority_arks'] << { 'ark' => AuthorityArk.mint }

    else

      # Validate the ARKs. Do it here so invalid ARKs can be highlighted in the staff interface.
      AuthorityArk.validate_arks(json['authority_arks'])

    end

    # Update the record in the database
    return core_update_from_json(json, extra_values, apply_nested_records)

  end


  def assimilate(victims)

    # Transfer Authority ARKs when merging agents
    begin
      victims.reject {|v| (v.class == self.class) && (v.id == self.id)}.each do |victim|
        AuthorityArk.filter(:agent_software_id => victim.id).update(:agent_software_id => self.id, :system_mtime => Time.now)
      end
    rescue Sequel::DatabaseError
      raise ConflictException.new("Cannot update authority_ark table")
    end

    # Do the merger
    core_assimilate(victims)

  end


end
