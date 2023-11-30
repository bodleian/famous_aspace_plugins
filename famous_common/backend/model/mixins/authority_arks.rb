module AuthorityArks

  def self.included(base)
    base.one_to_many(:authority_ark)

    base.def_nested_record(:the_property => :authority_arks,
                           :contains_records_of_type => :authority_ark,
                           :corresponding_to_association => :authority_ark)
  end

end
