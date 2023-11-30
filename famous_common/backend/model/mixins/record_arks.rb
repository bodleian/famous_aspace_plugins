module RecordArks

  def self.included(base)
    base.one_to_many(:record_ark)

    base.def_nested_record(:the_property => :record_arks,
                           :contains_records_of_type => :record_ark,
                           :corresponding_to_association => :record_ark)
  end

end
