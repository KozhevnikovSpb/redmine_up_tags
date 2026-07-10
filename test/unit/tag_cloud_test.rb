require File.expand_path('../../test_helper', __FILE__)

class TagCloudTest < ActiveSupport::TestCase
  fixtures :projects, :users, :trackers, :projects_trackers, :issue_statuses, :versions

  setup do
    User.stubs(:current).returns(users(:users_001))
    @project = projects(:projects_001)
  end

  test 'serializes filters as integer arrays' do
    cloud = TagCloud.new(project: @project, name: 'Filtered', status_filter: ['1', '', '1'])
    cloud.valid?
    assert_equal [1], cloud.status_filter
  end

  test 'only one system cloud is allowed per project' do
    TagCloud.ensure_system_cloud(@project)
    duplicate = TagCloud.new(project: @project, name: 'Duplicate', is_system: true)
    assert_not duplicate.valid?
  end

  test 'preference overrides default visibility' do
    cloud = TagCloud.create!(project: @project, name: 'Hidden', visible_by_default: false)
    user = users(:users_002)
    assert_not cloud.visible_for?(user)
    cloud.preferences.create!(user: user, visible: true)
    assert cloud.visible_for?(user)
  end
end
