class CreateTestModel < ActiveRecord::Migration[8.0]
  def change
    create_table :test_models do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
