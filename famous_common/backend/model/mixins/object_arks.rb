module ObjectArks

  def self.included(base)
    base.one_to_many(:object_ark)

    base.def_nested_record(:the_property => :object_arks,
                           :contains_records_of_type => :object_ark,
                           :corresponding_to_association => :object_ark)
  end

end
