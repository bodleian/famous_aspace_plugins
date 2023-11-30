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
    },
  },
}