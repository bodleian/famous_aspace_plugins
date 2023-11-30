# famous_common

This plug-in does everything to implement ARKs in ArchivesSpace except the user interface changes to enable cataloguers 
to see and edit ARKs in the staff interface. For that, the "record_arks", "object_arks" and "authority_arks" plug-ins 
must be installed alongside it. Each of the other plug-ins has a "depends_on_plugins" in their config.yml files to require
that this plug-in is installed, but this plug-in doesn't because that would cause a "plugin dependency cycle" error upon 
application startup.