#require 'securerandom'
#require 'uri'
#require 'net/http'
#require 'json'

module FamousArks


  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods


    def normalize_nmas

      # Ensure there is no slash or space on the end of these config options, as they are used to construct ARK URLs
      AppConfig[:record_ark_nma].gsub!(/[\/\s]+$/, '')
      AppConfig[:object_ark_nma].gsub!(/[\/\s]+$/, '')
      AppConfig[:authority_ark_nma].gsub!(/[\/\s]+$/, '')

    end


    def mint_for_storage

      # Just mints the NAAN and ARK name, not the full ARK URL, so all classes can call this generic method
      ark_name = ArkNameCache.get_ark_name
      if !ark_name.nil?
        return AppConfig[:ark_naan] + '/' + ark_name
      else
        raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_mint_failure"]})
      end

    end


    def reduce_ark_for_storage(arkstr)

      # Convert full URL ARKs to just the NAAN and the ARK name. Also remove hyphens which, while valid
      # in ARKs, are "identity inert", and so would permit duplicates if stored in the database.
      if arkstr.nil? or arkstr.strip.empty?
        return arkstr
      else
        return arkstr.partition(/ark:\/?/).reject{ |c| c.empty? }.last.tr('-','').strip
      end

    end


    def trigger_reindex(ids_to_reindex)

      # Bump the last-modified timestamps to trigger re-index, and increment lock versions to prevent stale updates
      begin
        self.filter(:id => ids_to_reindex).update(:system_mtime => Time.now, :lock_version => Sequel.expr(1) + :lock_version)
      rescue Sequel::DatabaseError
        raise ConflictException.new("Cannot trigger re-index")
      end

    end


  end


end

