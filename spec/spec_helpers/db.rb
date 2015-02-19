User.create!(:id => 1, :username => "bob")
User.create!(:id => 2, :username => "jane")

Workspace.create!(:id => 1, :user_id => 1, :title => "bob workspace 1", :description => "a")
Workspace.create!(:id => 2, :user_id => 1, :title => "bob workspace 2", :description => "1")
Workspace.create!(:id => 3, :user_id => 1, :title => "bob workspace 3", :description => "b")
Workspace.create!(:id => 4, :user_id => 1, :title => "bob workspace 4", :description => "2")
Workspace.create!(:id => 5, :user_id => 2, :title => "jane workspace 1", :description => "c")
Workspace.create!(:id => 6, :user_id => 2, :title => "jane workspace 2", :description => "3")

Task.create!(:id => 1, :workspace_id => 1, :name => "Buy milk")
Task.create!(:id => 2, :workspace_id => 1, :name => "Buy bananas")
Task.create!(:id => 3, :workspace_id => 1, :parent_id => 2, :name => "Green preferred")
Task.create!(:id => 4, :workspace_id => 1, :parent_id => 2, :name => "One bunch")

Post.create!(:id => 1, :user_id => 1, :subject => Workspace.first, :body => "first post!")
Post.create!(:id => 2, :user_id => 1, :subject => Task.first, :body => "this is important. get on it!")
Post.create!(:id => 3, :user_id => 2, :body => "Post without subject")