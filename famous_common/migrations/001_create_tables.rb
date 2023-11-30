require 'db/migrations/utils'

Sequel.migration do

  up do

    $stderr.puts("Add table for record ARKs")

    create_table(:record_ark) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false
      String :ark, :null => false, :index => true
      Integer :prime, :default => 1, :null => false    # Following convention of using Integer column for Boolean values
      Integer :resource_id, :null => true
      Integer :archival_object_id, :null => true
      apply_mtime_columns
    end

    alter_table(:record_ark) do
      add_unique_constraint([:ark, :prime], :name => "record_ark_uniq_ark_and_prime")
      add_foreign_key([:resource_id], :resource, :key => :id, :name => 'resource_record_ark_fk')
      add_foreign_key([:archival_object_id], :archival_object, :key => :id, :name => 'archival_object_record_ark_fk')
    end

    $stderr.puts("Add table for object ARKs")

    create_table(:object_ark) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false
      String :ark, :null => false
      Integer :resource_id, :null => true
      Integer :archival_object_id, :null => true
      apply_mtime_columns
    end

    alter_table(:object_ark) do
      add_foreign_key([:resource_id], :resource, :key => :id, :name => 'resource_object_ark_fk')
      add_foreign_key([:archival_object_id], :archival_object, :key => :id, :name => 'archival_object_object_ark_fk')
    end

  end

  down do

    $stderr.puts("Remove table for record ARKs")

    drop_table(:record_ark)

    $stderr.puts("Remove table for object ARKs")

    drop_table(:object_ark)

  end

end

