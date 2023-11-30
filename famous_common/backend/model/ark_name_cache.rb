require 'uri'
require 'net/http'
require 'json'

# This class implements a cache of unassigned ARKs, so the ARK minter server can go down temporarily without
# it preventing staff interface users from creating new records, or importing new EAD.

class ArkNameCache < Sequel::Model(:ark_name_cache)


  # Set the target cache size, and the size of batches to retrieve from the external minter
  @@CACHE_SIZE = 10000
  @@BATCH_SIZE = 1000


  def self.get_ark_name

    # Sometimes this is called as part of a long-running transaction (e.g. importing a big EAD file) so the
    # retrieval of the cached ARK name from the database must be done in a separate thread, otherwise it
    # would prevent other users from saving their work for several minutes.
    get_ark_name_thread = Thread.new {

      # Retrieve then delete a row from the cache (using a "for update" lock to prevent concurrent access)
      next_row_from_cache = nil
      DB.transaction do
        begin
          next_row_from_cache = ArkNameCache.for_update.first
          next_row_from_cache.delete
        rescue
          # The cache has run out, so try to replenish it.
          if replenish(@@BATCH_SIZE)
            next_row_from_cache = ArkNameCache.for_update.first
            next_row_from_cache.delete
          else
            Log.error("Cache has run out and cannot mint new ARK names")
          end
        end
      end

      Thread.current[:ark_name_row] = next_row_from_cache
    }

    # Wait for thread to finish and return a value
    get_ark_name_thread.join
    next_row_from_cache = get_ark_name_thread[:ark_name_row]

    unless next_row_from_cache.nil?

      # Replenish the cache whenever it is ready for a new batch of ARKs
      if next_row_from_cache.id % @@BATCH_SIZE == 0
        Thread.new {
          unless replenish(@@BATCH_SIZE)
            Log.error("Cannot replenish ARK names cache")
          end
        }
      end

      return next_row_from_cache.ark_name

    else

      return nil

    end

  end


  def self.replenish(quantity)

    if new_ark_names = retrieve_ark_names(quantity)
      Log.info("Replenishing cache with #{new_ark_names.count} new ARK names")
      begin
        ArkNameCache.import([:ark_name], new_ark_names.shuffle)
      rescue
        Log.error("Cannot store a batch of ARK names in the cache")
        return false
      end
    else
      return false
    end

    return true

  end


  def self.build

    # Count number of rows in cache
    row_count = ArkNameCache.count

    if row_count < @@CACHE_SIZE
      shortfall = @@CACHE_SIZE - row_count
      num_batches = shortfall / @@BATCH_SIZE
      if num_batches > 0
        # Cache is ready for at least one batch of new ARK names
        (1 .. num_batches).each do
          replenish(@@BATCH_SIZE)
        end
        new_row_count = ArkNameCache.count
        if new_row_count > row_count
          Log.info("ARK name cache updated from #{row_count} to #{new_row_count}")
          return true
        else
          Log.error("Cannot build ARK names cache")
          return false
        end
      else
        # Cache nearly full and not yet ready for a new batch
        return true
      end
    else
      # Cache is already full
      return true
    end

  end


  def self.retrieve_ark_names(quantity)

    uri = URI(AppConfig[:ark_minter_url] + '?n=' + quantity.to_s)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 1
    http.max_retries = 0
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
    request = Net::HTTP::Post.new(uri)
    begin
      response = http.request(request)
      return JSON.parse(response.body)
    rescue
      return nil
    end

  end


end
