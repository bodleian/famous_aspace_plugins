require 'db/migrations/utils'

Sequel.migration do

  up do

    $stderr.puts("Add table for subject/agent ARKs")

    create_table(:authority_ark) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false
      String :ark, :null => false, :index => true, :unique => true
      Integer :subject_id, :null => true
      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true
      apply_mtime_columns
    end

    alter_table(:authority_ark) do
      add_foreign_key([:subject_id], :subject, :key => :id, :name => 'subject_authority_ark_fk')
      add_foreign_key([:agent_person_id], :agent_person, :key => :id, :name => 'agent_person_authority_ark_fk')
      add_foreign_key([:agent_family_id], :agent_family, :key => :id, :name => 'agent_family_authority_ark_fk')
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id, :name => 'agent_corporate_entity_authority_ark_fk')
      add_foreign_key([:agent_software_id], :agent_software, :key => :id, :name => 'agent_software_authority_ark_fk')
    end

  end

  down do

    $stderr.puts("Remove table for subject/agent ARKs")

    drop_table(:authority_ark)

  end

end