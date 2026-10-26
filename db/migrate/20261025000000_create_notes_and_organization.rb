class CreateNotesAndOrganization < ActiveRecord::Migration[7.2]
  def change
    create_table :folders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :folders, [:user_id, :name], unique: true

    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :categories, [:user_id, :name], unique: true

    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :folder, foreign_key: { on_delete: :nullify }
      t.references :category, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.text :content, null: false, default: ""
      t.timestamps
    end
    add_index :notes, [:user_id, :updated_at]
  end
end
