# A set of methods that can be included in spec
# files to build fixtures.
module Fixtures

  TOGGL_REPORT = {
    'id' => 256_671_430,
    'pid' => 9_800_223,
    'tid' => nil,
    'uid' => 1_634_403,
    'description' => 'jt-1234 some random description',
    'start' => '2015-07-28T12:35:29+02:00',
    'end' => '2015-07-29T10:15:26+02:00',
    'updated' => '2015-07-30T09:12:11+02:00',
    'dur' => 143_498,
    'user' => 'Romain',
    'use_stop' => true,
    'client' => nil,
    'project' => 'Maintenance',
    'project_color' => '0',
    'project_hex_color' => '#4dc3ff',
    'task' => nil,
    'billable' => 0.0,
    'is_billable' => false,
    'cur' => 'USD',
    'tags' => []
  }

  def toggl_report
    TOGGL_REPORT
  end

  def toggl_report_duration_changed
    toggl_report.merge(
      'dur' => 230_112,
      'updated' => '2015-08-01T07:43:12+02:00'
    )
  end

  def toggl_report_issue_changed
    toggl_report.merge(
      'description' => 'jt-2345 some other description',
      'updated' => '2015-08-02T11:23:55+02:00'
    )
  end
end
