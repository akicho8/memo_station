class CreateArticles < ActiveRecord::Migration[4.2]
  def change
    create_table :articles do |t|
      t.string :title, :index => {:unique => true}
      t.text :body
      t.timestamps :null => false
    end
  end
end
