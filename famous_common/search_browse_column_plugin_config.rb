# This adds selectable columns to the staff interface (users can choose to display in their preferences.)
# Do NOT delete any of the options, unless you've checked preferences of every user to ensure nobody is using them,
# otherwise they'll get error messages when they log in.

module SearchAndBrowseColumnPlugin
  def self.config
    {
      'multi' => {
        :add => {
          'arks' => {
            :field => 'arks_full_u_sstr',
            :sortable => false,
          },
        },
      },
      'resource' => {
        :add => {
          'arks' => {
            :field => 'arks_full_u_sstr',
            :sortable => false,
          },
        },
      },
      'archival_object' => {
        :add => {
          'arks' => {
            :field => 'arks_full_u_sstr',
            :sortable => false,
          },
        },
      },
      'agent' => {
        :add => {
          'arks' => {
            :field => 'arks_full_u_sstr',
            :sortable => false,
          },
        },
      },
      'subject' => {
        :add => {
          'arks' => {
            :field => 'arks_full_u_sstr',
            :sortable => false,
          },
        },
      },
    }
  end
end