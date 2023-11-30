# famous_aspace_plugins

This repository contains four ArchivesSpace plug-ins which together implement ARKs in ArchivesSpace
according to the requirements of the [FAMOUS project](https://www.bodleian.ox.ac.uk/about/libraries/our-work/famous),
specifically the decision to store two different types of ARKs on metadata records (representing the record and the
object it describes as two distinct entities) and use ARKs as permalinks for authorities (i.e. agents and subjects.)

Each subdirectory is a plug-in. This is a workaround for limitations in the mechanism by which plug-ins can add 
sections to staff interface forms.

Together, they add the following:

* "Record ARKs" which will resolve to resource or archival object pages of the ArchivesSpace public user interface. 
  Because sometimes replacement records are prepared alongside the originals, the same record ARK can exist in two 
  records, but the ARK will only resolve to the oldest published one. These ARKs represent the record, not the object 
  it describes.
* "Object ARKs" which do not resolve to the public user interface because instead they resolve to new MARCO web site
  (https://marco.ox.ac.uk/). These ARKs represent the object itself (either a physical object or a born-digital object). 
  There is no uniqueness constraint as multiple records in ArchivesSpace can (and do) describe the same things.
* "Authority ARKs" which will resolve to subject or agent pages of the ArchivesSpace PUI. Each Authority ARK is unique 
  to one authority record.

Because records in ArchivesSpace (or the EAD when it is exported) are the definitive and permanent metadata descriptions, 
this plug-in mints all the above kinds of ARKs whenever a new record is created (at an appropriate level, such as item or 
file, in the case of Object ARKs.) But cataloguers are able to edit and replace ARKs (e.g. to deal with duplicate records 
about the same objects, duplicate agent or subject authorities, etc.)

ARKs are intended to be permalinks, which might outlive ArchivesSpace, so the data structure is designed for easy 
extraction in the future. Each type of ARK has its own MySQL table, and Record and Object ARKs are included as *unitid* 
elements in EAD exports (including via OAI-PMH.) Authority ARKs are exported as *extptr* in the relevant elements 
(e.g. *persname* for people.)

Config options are as follows:
```
AppConfig[:arks_enabled] = false                                                      # Necessary to disable core ArchivesSpace ARK
AppConfig[:ark_naan] = '12345'                                                        # Organizational identifier
AppConfig[:ark_prefix] = 'ark:/'                                                      # Prefix, see https://arks.org/about/
AppConfig[:record_ark_nma] = 'https://aspace.pui.hostname/'                           # NMA, https://arks.org/about/
AppConfig[:object_ark_nma] = 'https://object.database.hostname/'                      # NMA, https://arks.org/about/
AppConfig[:authority_ark_nma] = 'https://aspace.pui.hostname/'                        # NMA, https://arks.org/about/
AppConfig[:object_ark_automint_levels] = %w[file item surrogate folder collection]    # Levels (or otherlevels) to mint object ARKs for
AppConfig[:ark_minter_url] = 'https://minter.hostname/path/to/return/ark/names'       # URL for minting service
```
The minter is an external service, which returns ARK names (the bit that comes after the prefix) as JSON arrays, and
takes a 'n' parameter to specific the number to mint. This plug-in cannot mint its own ARKs, but it does keep a cache of 
unassigned ARK names to allow staff to carry on creating records even if the external minter is temporarily unavailable.

To run tests, use:
```bash
build/run backend:test -Dexample="Famous ARKs Tests"
```
This plug-in has no bulk-load has no bulk-loading feature to add ARKs to existing records. Because over half a million 
ARKs were required for the initial load on the Bodleian's ArchivesSpace system, this was done using an SQL procedure to 
add them directly to the database.

Display of ARKs in the public user interface are not handled by any of these plug-ins. That would require overriding .erb 
templates, which can cause compatibility issues when upgrading to a newer ArchivesSpace release. It is better to do that 
in another local plug-in intended for that purpose.

New ARKs are minted for archival objects created by the Load via Spreadsheet function. But there is no way to specify ARKs 
in the spreadsheet. So you cannot export records to a spreadsheet, modify them outside of ArchivesSpace, re-import the 
spreadsheet, and preserve their permalinks. You have to use EAD for that purpose. Note also that Authority ARKs are exported
in EAD, but not imported.