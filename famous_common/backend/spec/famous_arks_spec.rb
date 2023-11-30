require 'spec_helper'

describe 'Famous ARKs Tests' do

  shortarkregex = Regexp.new(/^\d{5}\/[A-Za-z0-9=~*+@_$.\/\-]+$/)
  shortrecordark = AppConfig[:ark_naan] + '/qwerty'
  fullrecordark = AppConfig[:record_ark_nma] + '/ark:/' + shortrecordark
  shortobjectark = AppConfig[:ark_naan] + '/asdf'
  fullobjectark = AppConfig[:object_ark_nma] + '/ark:/' + shortobjectark
  shortauthorityark = AppConfig[:ark_naan] + '/zxcv'
  fullauthorityark = AppConfig[:authority_ark_nma] + '/ark:/' + shortauthorityark

  it "stores full url arks in json as just the naan and ark name in the database" do
    r = Resource.create_from_json(build(:json_resource, :record_arks => [{:ark => fullrecordark}], :object_arks => [{:ark => fullobjectark}]), :repo_id => $repo_id)
    Resource[r.id].record_ark[0].ark.should eq(shortrecordark)
    Resource[r.id].object_ark[0].ark.should eq(shortobjectark)
    r.delete
    a = ArchivalObject.create_from_json(build(:json_archival_object, :record_arks => [{:ark => fullrecordark}], :object_arks => [{:ark => fullobjectark}]), :repo_id => $repo_id)
    ArchivalObject[a.id].record_ark[0].ark.should eq(shortrecordark)
    ArchivalObject[a.id].object_ark[0].ark.should eq(shortobjectark)
    s = Subject.create_from_json(build(:json_subject, :authority_arks => [{:ark => fullauthorityark}]))
    Subject[s.id].authority_ark[0].ark.should eq(shortauthorityark)
    s.delete
    ap = AgentPerson.create_from_json(build(:json_agent_person, :authority_arks => [{:ark => fullauthorityark}]))
    AgentPerson[ap.id].authority_ark[0].ark.should eq(shortauthorityark)
    ap.delete
    af = AgentFamily.create_from_json(build(:json_agent_family, :authority_arks => [{:ark => fullauthorityark}]))
    AgentFamily[af.id].authority_ark[0].ark.should eq(shortauthorityark)
    af.delete
    ac = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity, :authority_arks => [{:ark => fullauthorityark}]))
    AgentCorporateEntity[ac.id].authority_ark[0].ark.should eq(shortauthorityark)
    ac.delete
    as = AgentSoftware.create_from_json(build(:json_agent_software, :authority_arks => [{:ark => fullauthorityark}]))
    AgentSoftware[as.id].authority_ark[0].ark.should eq(shortauthorityark)
    as.delete
  end

  it "mints a record ark for every new record" do
    r = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    a = ArchivalObject.create_from_json(build(:json_archival_object), :repo_id => $repo_id)
    Resource[r.id].record_ark.count.should eq(1)
    Resource[r.id].record_ark[0].ark.should match(shortarkregex)
    ArchivalObject[a.id].record_ark.count.should eq(1)
    ArchivalObject[a.id].record_ark[0].ark.should match(shortarkregex)
  end

  it "mints an object ark for new records at appropriate levels" do
    r1 = Resource.create_from_json(build(:json_resource, :level => 'item'), :repo_id => $repo_id)
    r2 = Resource.create_from_json(build(:json_resource, :level => 'collection'), :repo_id => $repo_id)
    a1 = ArchivalObject.create_from_json(build(:json_archival_object, :level => 'file'), :repo_id => $repo_id)
    a2 = ArchivalObject.create_from_json(build(:json_archival_object, :level => 'item'), :repo_id => $repo_id)
    a3 = ArchivalObject.create_from_json(build(:json_archival_object, :level => 'series'), :repo_id => $repo_id)
    Resource[r1.id].object_ark.count.should eq(1)
    Resource[r1.id].object_ark[0].ark.should match(shortarkregex)
    Resource[r2.id].object_ark.count.should eq(0)
    ArchivalObject[a1.id].object_ark.count.should eq(1)
    ArchivalObject[a1.id].object_ark[0].ark.should match(shortarkregex)
    ArchivalObject[a2.id].object_ark.count.should eq(1)
    ArchivalObject[a2.id].object_ark[0].ark.should match(shortarkregex)
    ArchivalObject[a3.id].object_ark.count.should eq(0)
  end

  it "mints a new record ark if the old one is deleted" do
    r = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    a = ArchivalObject.create_from_json(build(:json_archival_object), :repo_id => $repo_id)
    json = Resource.to_jsonmodel(r.id)
    oldark = json["record_arks"][0]['ark']
    json["record_arks"] = []
    r.update_from_json(json)
    Resource[r.id].record_ark.count.should eq(1)
    Resource[r.id].record_ark[0].ark.should match(shortarkregex)
    Resource[r.id].record_ark[0].ark.should_not eq(oldark)
    json = ArchivalObject.to_jsonmodel(a.id)
    oldark = json["record_arks"][0]['ark']
    json["record_arks"] = []
    a.update_from_json(json)
    ArchivalObject[a.id].record_ark.count.should eq(1)
    ArchivalObject[a.id].record_ark[0].ark.should match(shortarkregex)
    ArchivalObject[a.id].record_ark[0].ark.should_not eq(oldark)
  end

  it "mints new arks on demand" do
    r = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
    a = ArchivalObject.create_from_json(build(:json_archival_object), :repo_id => $repo_id)
    json = Resource.to_jsonmodel(r.id)
    json["record_arks"] = [{:ark => ' '}]
    json["object_arks"] = [{:ark => ' '}]
    r.update_from_json(json)
    json = ArchivalObject.to_jsonmodel(a.id)
    json["record_arks"] = [{:ark => ' '}]
    json["object_arks"] = [{:ark => ' '}]
    a.update_from_json(json)
    Resource[r.id].record_ark.count.should eq(1)
    ArchivalObject[a.id].record_ark.count.should eq(1)
    Resource[r.id].object_ark.count.should eq(1)
    ArchivalObject[a.id].object_ark.count.should eq(1)
    expect([Resource[r.id].record_ark, Resource[r.id].object_ark, ArchivalObject[a.id].record_ark, ArchivalObject[a.id].object_ark].flatten.all?{ |ra| ra.ark.match?(shortarkregex) }).to be(true)
  end

  # TODO: Test for specific errors
  it "permits two records (and no more) to have the same record ark" do
    a1 = ArchivalObject.create_from_json(build(:json_archival_object, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    a2 = ArchivalObject.create_from_json(build(:json_archival_object, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    expect {
      a3 = ArchivalObject.create_from_json(build(:json_archival_object, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    }.to raise_error
    expect {
      r1 = Resource.create_from_json(build(:json_resource, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    }.to raise_error
    a1.delete
    a3 = ArchivalObject.create_from_json(build(:json_archival_object, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    a2.delete
    r1 = Resource.create_from_json(build(:json_resource, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    expect {
      r2 = Resource.create_from_json(build(:json_resource, :record_arks => [{:ark => fullrecordark}]), :repo_id => $repo_id)
    }.to raise_error
  end

  # TODO: These tests don't work because the indexer/solr aren't running, so it cannot resolve any ARKs. Move to indexer test suite?
  # it "editing records that share a record ark should not change which resolves" do
  #   json1 = build(:json_archival_object, :record_arks => [{:ark => fullrecordark}])
  #   json2 = build(:json_archival_object, :record_arks => [{:ark => fullrecordark}])
  #   a1 = ArchivalObject.create_from_json(json1, :repo_id => $repo_id)
  #   a2 = ArchivalObject.create_from_json(json2, :repo_id => $repo_id)
  #   response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => ArchivalObject[a1.id].record_ark[0].ark)
  #   expect(response).to eq(a1.uri)
  #   ArchivalObject[a1.id].record_ark[0].prime.should eq(1)
  #   ArchivalObject[a2.id].record_ark[0].prime.should eq(0)
  #   json2['title'] = 'New Title'
  #   json2['lock_version'] = 0
  #   a2.update_from_json(json2)
  #   response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => ArchivalObject[a1.id].record_ark[0].ark)
  #   expect(response).to eq(a1.uri)
  #   json1['title'] = 'New Title'
  #   json1['lock_version'] = 0
  #   a1.update_from_json(json1)
  #   response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => ArchivalObject[a1.id].record_ark[0].ark)
  #   expect(response).to eq(a1.uri)
  # end
  #
  # it "deleting a finding aid makes record arks resolve to records in a duplicate finding aid" do
  #   numsubrecs = 10
  #   r1 = Resource.create_from_json(build(:json_resource), :repo_id => $repo_id)
  #   r2 = Resource.create_from_json(build(:json_resource, :record_arks => [{:ark => Resource[r1.id].record_ark[0].ark}]), :repo_id => $repo_id)
  #   r1subrecords = r2subrecords = []
  #   numsubrecs.times do |i|
  #     r1subrecords[i] = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => r1.uri}), :repo_id => $repo_id)
  #     r2subrecords[i] = ArchivalObject.create_from_json(build(:json_archival_object, :resource => {:ref => r2.uri}, :record_arks => [{:ark => ArchivalObject[r1subrecords[i].id].record_ark[0].ark}]), :repo_id => $repo_id)
  #   end
  #   response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => Resource[r1.id].record_ark[0].ark)
  #   expect(response).to eq(r1.uri)
  #   numsubrecs.times do |i|
  #     response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => ArchivalObject[r1subrecords[i].id].record_ark[0].ark)
  #     expect(response).to eq(r1subrecords[i].uri)
  #   end
  #   r1.delete
  #   response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => Resource[r2.id].record_ark[0].ark)
  #   expect(response).to eq(r2.uri)
  #   numsubrecs.times do |i|
  #     response = JSONModel::HTTP.get_json("#{JSONModel::HTTP.backend_url}/resolve_ark_list", :ark => ArchivalObject[r2subrecords[i].id].record_ark[0].ark)
  #     expect(response).to eq(r2subrecords[i].uri)
  #   end
  # end

  it "merging resources transfers the deleted resource's arks to the retained one" do
    r1 = Resource.create_from_json(build(:json_resource, :level => 'item'), :repo_id => $repo_id)
    r2 = Resource.create_from_json(build(:json_resource, :level => 'item'), :repo_id => $repo_id)
    r2rark = Resource[r2.id].record_ark[0].ark
    r2oark = Resource[r2.id].object_ark[0].ark
    request = JSONModel(:merge_request).new
    request.target = {'ref' => r1.uri}
    request.victims = [{'ref' => r2.uri}]
    request.save(:record_type => 'resource')
    Resource[r1.id].record_ark[1].ark.should eq(r2rark)
    Resource[r1.id].object_ark[1].ark.should eq(r2oark)
  end
  
  it "mints an authority ark for all new subjects and agents" do
    s = Subject.create_from_json(build(:json_subject))
    ap = AgentPerson.create_from_json(build(:json_agent_person))
    af = AgentFamily.create_from_json(build(:json_agent_family))
    ac = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity))
    as = AgentSoftware.create_from_json(build(:json_agent_software))
    Subject[s.id].authority_ark.count.should eq(1)
    Subject[s.id].authority_ark[0].ark.should match(shortarkregex)
    AgentPerson[ap.id].authority_ark.count.should eq(1)
    AgentPerson[ap.id].authority_ark[0].ark.should match(shortarkregex)
    AgentFamily[af.id].authority_ark.count.should eq(1)
    AgentFamily[af.id].authority_ark[0].ark.should match(shortarkregex)
    AgentCorporateEntity[ac.id].authority_ark.count.should eq(1)
    AgentCorporateEntity[ac.id].authority_ark[0].ark.should match(shortarkregex)
    AgentSoftware[as.id].authority_ark.count.should eq(1)
    AgentSoftware[as.id].authority_ark[0].ark.should match(shortarkregex)
  end

  # TODO: Test for specific errors
  it "do not permit two authorities to have the same authority ark" do
    s1 = Subject.create_from_json(build(:json_subject, :authority_arks => [{:ark => fullauthorityark}]))
    expect {
      s2 = Subject.create_from_json(build(:json_subject, :authority_arks => [{:ark => fullauthorityark}]))
    }.to raise_error
    s1.delete
    s2 = Subject.create_from_json(build(:json_subject, :authority_arks => [{:ark => fullauthorityark}]))
    Subject[s2.id].authority_ark[0].ark.should eq(shortauthorityark)
    expect {
      ap = AgentPerson.create_from_json(build(:json_agent_person, :authority_arks => [{:ark => fullauthorityark}]))
    }.to raise_error
    s2.delete
    ap = AgentPerson.create_from_json(build(:json_agent_person, :authority_arks => [{:ark => fullauthorityark}]))
    AgentPerson[ap.id].authority_ark[0].ark.should eq(shortauthorityark)
  end

  it "merging subjects transfers the deleted subject's arks to the retained one" do
    s1 = Subject.create_from_json(build(:json_subject))
    s2 = Subject.create_from_json(build(:json_subject))
    s2ark = Subject[s2.id].authority_ark[0].ark
    request = JSONModel(:merge_request).new
    request.target = {'ref' => s1.uri}
    request.victims = [{'ref' => s2.uri}]
    request.save(:record_type => 'subject')
    Subject[s1.id].authority_ark[1].ark.should eq(s2ark)
  end

  it "merging agents transfers the deleted agent's arks to the retained one" do
    ap1 = AgentPerson.create_from_json(build(:json_agent_person))
    ap2 = AgentPerson.create_from_json(build(:json_agent_person))
    ap2ark = AgentPerson[ap2.id].authority_ark[0].ark
    request = JSONModel(:merge_request).new
    request.target = {'ref' => ap1.uri}
    request.victims = [{'ref' => ap2.uri}]
    request.save(:record_type => 'agent')
    AgentPerson[ap1.id].authority_ark[1].ark.should eq(ap2ark)
  end



end
