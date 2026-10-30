class WorkoutsController < ApplicationController
  before_action :require_login
  before_action :set_workout, only: [:show, :edit, :update, :destroy]
  before_action :load_exercises, only: [:index, :new, :create, :edit, :update]

  def index
    @exercise = current_user.exercises.find(params[:exercise_id]) if params[:exercise_id].present?
    @workouts = current_user.workouts
    @workouts = @workouts.where(id: WorkoutExercise.where(exercise_id: @exercise.id).select(:workout_id)) if @exercise
    @total = @workouts.count
    @page = [params[:page].to_i, 1].max
    @workouts = @workouts.order(workout_date: :desc, id: :desc).includes(workout_exercises: [:exercise, :exercise_sets]).limit(20).offset((@page - 1) * 20)
  end

  def show
  end

  def new
    @workout = current_user.workouts.new(workout_date: Date.current)
    add_exercise
  end

  def create
    @workout = current_user.workouts.new(workout_params)
    save_or_extend(:new)
  end

  def edit
  end

  def update
    @workout.assign_attributes(workout_params)
    save_or_extend(:edit)
  end

  def destroy
    @workout.destroy!
    redirect_to workouts_path, notice: "Workout deleted.", status: :see_other
  end

  private

  def set_workout
    @workout = current_user.workouts.includes(workout_exercises: [:exercise, :exercise_sets]).find(params[:id])
  end

  def load_exercises
    @exercises = current_user.exercises.order(:name)
  end

  def add_exercise
    entry = @workout.workout_exercises.build(exercise_order: @workout.workout_exercises.size + 1)
    entry.exercise_sets.build(set_number: 1)
  end

  def save_or_extend(template)
    if params[:add_exercise].present?
      add_exercise
      render template
    elsif params[:add_set].present?
      entry = @workout.workout_exercises[params[:add_set].to_i]
      raise ActiveRecord::RecordNotFound unless entry
      entry.exercise_sets.build(set_number: entry.exercise_sets.size + 1)
      render template
    elsif @workout.save
      redirect_to @workout, notice: "Workout saved.", status: :see_other
    else
      render template, status: :unprocessable_entity
    end
  end

  def workout_params
    params.require(:workout).permit(:name, :workout_date, :notes,
      workout_exercises_attributes: [:id, :exercise_id, :exercise_order, :_destroy,
        exercise_sets_attributes: [:id, :set_number, :repetitions, :weight, :_destroy]])
  end
end
