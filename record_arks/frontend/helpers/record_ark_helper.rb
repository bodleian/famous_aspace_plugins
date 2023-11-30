module RecordArkHelper

  def self.get_ark_info(arkstr, recordhash, current_repo)

    # Get facts about the record the ARK is in
    recorduri = recordhash['uri']

    # Go no further if this is a brand new record that has failed validation
    if recorduri.nil?
      return "No, because this record has not yet been saved."
    end

    # Send API request to get a list of potential records that could resolve, depending on precedence and publish status
    ark_resolver_response = JSONModel::HTTP.get_json('/resolve_record_ark_for_staff', :ark => arkstr.partition(/ark:\/?/).reject { |c| c.empty? }.last)
    if ark_resolver_response.nil?
      preferred = secondary = {}
    else
      preferred = ark_resolver_response[0] || {}
      secondary = ark_resolver_response[1] || {}
    end

    # Parse the API response to determine whether the ARK resolves to the current record
    resolvemsg = ""
    otherrecordmsg = ""
    if preferred['uri'] == recorduri
      if preferred['published']
        resolvemsg = "Yes."
      else
        resolvemsg = "No, because this record is unpublished."
      end
      if !secondary.empty?
        otherhref = AppConfig[:frontend_proxy_url] + '/resolve/readonly?uri=' + secondary['uri'] + '&autoselect_repo=true'
        if secondary['repo_id'] != current_repo.id
          otheronclick = 'return confirmRepoSwitch();'
        else
          otheronclick = ''
        end
        if secondary['published']
          if preferred['published']
            otherrecordmsg = "There is also a <a href='#{otherhref}' onclick='#{otheronclick}' target='_blank'>newer record</a> with the same ARK which is published but this record takes precedence."
          else
            otherrecordmsg = "There is a <a href='#{otherhref}' onclick='#{otheronclick}' target='_blank'>newer record</a> with the same ARK which is published."
          end
        else
          otherrecordmsg = "There is also a <a href='#{otherhref}' onclick='#{otheronclick}' target='_blank'>newer record</a> with the same ARK which is unpublished too."
        end
      end
    else
      otherhref = AppConfig[:frontend_proxy_url] + '/resolve/readonly?uri=' + preferred['uri'] + '&autoselect_repo=true'
      if preferred['repo_id'] != current_repo.id
        otheronclick = 'return confirmRepoSwitch();'
      else
        otheronclick = ''
      end
      if preferred['published']
        resolvemsg = "No."
        otherrecordmsg = "There is an <a href='#{otherhref}' onclick='#{otheronclick}' target='_blank'>older record</a> with the same ARK which takes precedence."
      elsif secondary['published']
        resolvemsg = "Yes."
        otherrecordmsg = "There is also an <a href='#{otherhref}' onclick='#{otheronclick}' target='_blank'>older record</a> with the same ARK which would take precedence but it is unpublished."
      else
        resolvemsg = "No, because this record is unpublished."
        otherrecordmsg = "There is an <a href='#{otherhref}' onclick='#{otheronclick}' target='_blank'>older record</a> with the same ARK which would take precedence but it is unpublished too."
      end
    end

    return "#{resolvemsg} #{otherrecordmsg}".strip

  end

end
