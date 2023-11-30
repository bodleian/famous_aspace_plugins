# Override methods in EAD importer
require_relative 'converters/ead_importer_override'

# Add classes to handle the EAD exporter hooks below
require_relative 'exporters/ead_exporter_override'

# Use hooks to export Record and Object ARKs as extra unitids
EADSerializer.add_serialize_step(RecordArkSerialize)
EADSerializer.add_serialize_step(ObjectArkSerialize)
EAD3Serializer.add_serialize_step(RecordArkSerializeEad3)
EAD3Serializer.add_serialize_step(ObjectArkSerializeEad3)

# Use hooks to export Authority ARKs as extptr/ptr
EADSerializer.add_serialize_step(AuthorityArkSerialize)
EAD3Serializer.add_serialize_step(AuthorityArkSerializeEad3)

# Strip off any trailing slashes in URLs in config options
FamousArk.normalize_nmas

# Populate ARK cache
ArkNameCache.build

# Schedule hourly task to ensure ARK cache is at or near its target size
# (the if statement prevents this from breaking rspec tests)
if ArchivesSpaceService.settings.respond_to?(:scheduler)
  ArchivesSpaceService.settings.scheduler.cron("0 */1 * * *", :tags => 'build_ark_name_cache', :allow_overlapping => false) do
    ArkNameCache.build
  end
end

