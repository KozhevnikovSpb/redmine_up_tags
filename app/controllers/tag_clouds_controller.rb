class TagCloudsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize, except: [:toggle_visibility]
  before_action :ensure_system_cloud

  def index
    @tag_clouds = @project.tag_clouds.order(:position, :id)
  end

  def new
    @tag_cloud = TagCloud.new(project: @project, visible_by_default: true, is_system: false, position: (@project.tag_clouds.maximum(:position) || 0) + 1)
    load_filter_options
  end

  def create
    @tag_cloud = TagCloud.new(tag_cloud_params)
    @tag_cloud.project = @project
    @tag_cloud.created_by = User.current
    if @tag_cloud.position.blank?
      @tag_cloud.position = (@project.tag_clouds.maximum(:position) || 0) + 1
    end

    if @tag_cloud.save
      redirect_to project_settings_path(@project, tab: 'tags'), notice: l(:notice_tag_cloud_created, default: 'Tag cloud was successfully created.')
    else
      load_filter_options
      render :new
    end
  end

  def edit
    @tag_cloud = @project.tag_clouds.find(params[:id])
    load_filter_options
  end

  def update
    @tag_cloud = @project.tag_clouds.find(params[:id])
    if @tag_cloud.update(tag_cloud_params)
      redirect_to project_settings_path(@project, tab: 'tags'), notice: l(:notice_tag_cloud_updated, default: 'Tag cloud was successfully updated.')
    else
      load_filter_options
      render :edit
    end
  end

  def destroy
    @tag_cloud = @project.tag_clouds.find(params[:id])
    if @tag_cloud.is_system?
      redirect_to project_settings_path(@project, tab: 'tags'), alert: l(:alert_cannot_delete_system_cloud, default: 'System cloud cannot be deleted.')
    else
      @tag_cloud.destroy
      redirect_to project_settings_path(@project, tab: 'tags'), notice: l(:notice_tag_cloud_deleted, default: 'Tag cloud was successfully deleted.')
    end
  end

  private

  def ensure_system_cloud
    TagCloud.ensure_system_cloud(@project)
  end

  def load_filter_options
    @statuses = IssueStatus.sorted
    @trackers = @project.trackers.order(:position)
    @versions = @project.versions.order(:effective_date, :name)
  end

  def tag_cloud_params
    params.require(:tag_cloud).permit(
      :name,
      :visible_by_default,
      :position,
      status_filter: [],
      version_filter: [],
      tracker_filter: []
    )
  end
end