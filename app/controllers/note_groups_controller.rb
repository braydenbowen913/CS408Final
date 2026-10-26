# Shared CRUD for the two flat organization lists. All lookups are user-scoped.
class NoteGroupsController < ApplicationController
  before_action :require_login
  before_action :load_groups
  before_action :set_group, only: [:edit, :update, :destroy]

  def index
    @group = @groups.new
    render "note_groups/index"
  end

  def create
    @group = @groups.new(group_params)
    if @group.save
      redirect_to @index_path, notice: "#{@label} created.", status: :see_other
    else
      render "note_groups/index", status: :unprocessable_entity
    end
  end

  def edit
    render "note_groups/edit"
  end

  def update
    if @group.update(group_params)
      redirect_to @index_path, notice: "#{@label} saved.", status: :see_other
    else
      render "note_groups/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy!
    redirect_to @index_path, notice: "#{@label} deleted. Its notes have been kept.", status: :see_other
  end

  private

  def load_groups
    @groups = current_user.public_send(controller_name).order(:name)
    @label = @groups.klass.model_name.human
    @index_path = url_for(action: :index, only_path: true)
  end

  def set_group
    @group = @groups.find(params[:id])
  end

  def group_params
    params.require(@groups.klass.model_name.param_key).permit(:name)
  end
end
