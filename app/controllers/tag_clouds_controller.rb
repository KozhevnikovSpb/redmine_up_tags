class TagCloudsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize, except: [:toggle_visibility]

  def index
    @tag_clouds = @project.tag_clouds.order(:position, :id)
  end

  def new
    @tag_cloud = TagCloud.new(project: @project, visible_by_default: true, is_system: false)
  end

  def create
    @tag_cloud = TagCloud.new(tag_cloud_params)
    @tag_cloud.project = @project
    @tag_cloud.created_by = User.current
    @tag_cloud.position = (@project.tag_clouds.maximum(:position) || 0) + 1

    if @tag_cloud.save
      redirect_to project_settings_path(@project, tab: 'tags'), notice: 'Tag cloud was successfully created.'
    else
      render :new
    end
  end

  def edit
    @tag_cloud = @project.tag_clouds.find(params[:id])
  end

  def update
    @tag_cloud = @project.tag_clouds.find(params[:id])
    if @tag_cloud.update(tag_cloud_params)
      redirect_to project_settings_path(@project, tab: 'tags'), notice: 'Tag cloud was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @tag_cloud = @project.tag_clouds.find(params[:id])
    if @tag_cloud.is_system?
      redirect_to project_settings_path(@project, tab: 'tags'), alert: 'System cloud cannot be deleted.'
    else
      @tag_cloud.destroy
      redirect_to project_settings_path(@project, tab: 'tags'), notice: 'Tag cloud was successfully deleted.'
    end
  end

  private

  def tag_cloud_params
    params.require(:tag_cloud).permit(
      :name,
      :visible_by_default,
      status_filter: [],
      version_filter: [],
      tracker_filter: []
    )
  end
end