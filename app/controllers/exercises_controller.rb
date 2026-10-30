class ExercisesController < ApplicationController
  before_action :require_login
  before_action :set_exercise, only: [:edit, :update, :destroy]

  def index
    @exercises = current_user.exercises.order(:name)
    @exercise = current_user.exercises.new
  end

  def create
    @exercise = current_user.exercises.new(exercise_params)
    if @exercise.save
      redirect_to exercises_path, notice: "Exercise created.", status: :see_other
    else
      @exercises = current_user.exercises.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to exercises_path, notice: "Exercise saved.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @exercise.destroy
      redirect_to exercises_path, notice: "Exercise deleted.", status: :see_other
    else
      redirect_to exercises_path, alert: "This exercise is used in workout history. Remove it from those workouts before deleting it.", status: :see_other
    end
  end

  private

  def set_exercise
    @exercise = current_user.exercises.find(params[:id])
  end

  def exercise_params
    params.require(:exercise).permit(:name, :muscle_group, :description)
  end
end
