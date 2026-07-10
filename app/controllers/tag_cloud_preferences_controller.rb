class TagCloudPreferencesController < ApplicationController
  before_action :find_project_by_project_id
  before_action :find_tag_cloud

  def toggle
    return deny_access unless User.current.allowed_to?(:select_tag_clouds, @project)

    preference = @tag_cloud.preferences.find_or_initialize_by(user: User.current)
    current_visibility = preference.persisted? ? preference.visible? : @tag_cloud.visible_by_default?
    preference.visible = !current_visibility
    preference.save!

    redirect_back fallback_location: project_issues_path(@project)
  end

  private

  def find_tag_cloud
    @tag_cloud = @project.tag_clouds.unscoped.find(params[:tag_cloud_id])
  end
end
