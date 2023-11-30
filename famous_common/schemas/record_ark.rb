{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "ark" => {
        "type" => "string",
        "maxLength" => 255,
        "required" => false,
        # NOTE: The ARK field is required, and the database table is set up not to allow nulls, but setting
        # required to false here allows it to be left blank, and the backend will generate a new ARK
      },
      "prime" => {
        "type" => "boolean",
        "default" => true,
        "readonly" => true,
        # NOTE: This isn't really a property of the Record ARK. It is a true/false flag (stored in the
        # database as 1 or 0) to allow two, but not more, records to have the same Record ARK.
      },
    },
  },
}