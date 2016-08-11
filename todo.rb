require 'pry'

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def list_complete?(list)
    todos_remaining_count(list) == 0 && todos_count(list) > 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end
end

before do
  @lists = session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the list name is invalid. Otherwise we will return nil
def error_for_list_name(name)
  if !(1..100).cover? name.length
    'The list name must be between 1 and 100 characters'
  elsif session[:lists].any? { |list| list[:name] == name }
    'That list already exists!'
  end
end

# Return an error message if the todo name is invalid
def error_for_todo(name)
  id = params[:list_id].to_i
  if !(1..100).cover? name.length
    'The todo must be between 1 and 100 characters'
  end
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: params[:todo], completed: false }
    session[:success] = "Todo added."
    redirect "/lists/#{@list_id}"
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created!'
    redirect '/lists'
  end
end

# Display a todo list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated!'
    redirect "/lists/#{@list_id}"
  end
end

# Delete an existing todo list
post '/lists/:id/delete' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'The list has been deleted!'
  redirect "/lists"
end

# Delete a todo from a list
post '/lists/:list_id/todos/:id/delete' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  id = params[:id].to_i
  @list[:todos].delete_at(id)
  session[:success] = 'The list has been deleted!'
  redirect "/lists/#{@list_id}"
end

#Update the status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][id][:completed] = is_completed
  session[:success] = 'The todo has been updated!'
  redirect "/lists/#{@list_id}"
end

#Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  session[:success] = 'All todos have been completed!'
  @list[:todos].each { |todo| todo[:completed] = true }
  redirect "/lists/#{@list_id}"
end
