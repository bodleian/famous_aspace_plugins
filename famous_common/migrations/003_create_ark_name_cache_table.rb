require 'db/migrations/utils'

Sequel.migration do

  up do

    $stderr.puts("Add table for a cache of unassigned ARK names")

    create_table(:ark_name_cache) do
      primary_key :id
      String :ark_name, :null => false
    end

  end

  down do

    $stderr.puts("Remove table for cache of unassigned ARK names")

    drop_table(:ark_name_cache)

  end

end

