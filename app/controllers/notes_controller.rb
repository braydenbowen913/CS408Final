class NotesController < ApplicationController
  before_action :require_login
  before_action :set_note, only: [:show, :edit, :update, :destroy]
  before_action :load_organization, only: [:index, :search, :new, :create, :edit, :update]

  def index
    load_notes
  end

  def search
    @search_page = true
    load_notes
    render :index
  end

  def show
  end

  def new
    @note = current_user.notes.new
  end

  def create
    @note = current_user.notes.new(note_params)
    if @note.save
      redirect_to @note, notice: "Note created.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @note.update(note_params)
      redirect_to @note, notice: "Note saved.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy!
    redirect_to notes_path, notice: "Note deleted.", status: :see_other
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def load_organization
    @folders = current_user.folders.order(:name)
    @categories = current_user.categories.order(:name)
  end

  def load_notes
    @query = params[:q].to_s.strip
    @folder = current_user.folders.find(params[:folder_id]) if params[:folder_id].present?
    @category = current_user.categories.find(params[:category_id]) if params[:category_id].present?
    @notes = current_user.notes.includes(:folder, :category).recent_first
    @notes = @notes.search(@query) if @query.present?
    @notes = @notes.where(folder: @folder) if @folder
    @notes = @notes.where(category: @category) if @category
    @page = [params[:page].to_i, 1].max
    @total = @notes.count
    @notes = @notes.limit(20).offset((@page - 1) * 20)
  end

  def note_params
    params.require(:note).permit(:title, :content, :folder_id, :category_id)
  end
end
