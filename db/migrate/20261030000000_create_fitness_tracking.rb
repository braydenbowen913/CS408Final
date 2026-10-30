class CreateFitnessTracking < ActiveRecord::Migration[7.2]
  def change
    create_table :exercises do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :muscle_group
      t.text :description
      t.timestamps
    end
    add_index :exercises, [:user_id, :name], unique: true

    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.date :workout_date, null: false
      t.text :notes
      t.timestamps
    end
    add_index :workouts, [:user_id, :workout_date]

    create_table :workout_exercises do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :exercise_order, null: false
      t.timestamps
    end
    create_table :exercise_sets do |t|
      t.references :workout_exercise, null: false, foreign_key: true
      t.integer :set_number, null: false
      t.integer :repetitions, null: false
      t.decimal :weight, precision: 10, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :exercise_sets, "set_number > 0 AND repetitions > 0 AND weight >= 0", name: "exercise_sets_valid_values"
    add_check_constraint :workout_exercises, "exercise_order > 0", name: "workout_exercises_valid_order"
  end
end
