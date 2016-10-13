require 'sinatra'
require 'data_mapper'


DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/project3.db")
set :public_folder, File.dirname(__FILE__) + '/static'

enable :sessions
set :set_session_secret, "test"

class User
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :email, String
	property :username, String
	property :password, String

end


class Todo
	include DataMapper::Resource
	property :id, Serial
	property :task, String
	property :done, Boolean
	property :user_id, Integer
	property :upvotes, Integer
end

class Vote
	include DataMapper::Resource
	belongs_to :Todo 
	property :todo_id, Serial
	property :user_id, Serial --force
	property :vote, Boolean
end


DataMapper.finalize

Todo.auto_upgrade!
User.auto_upgrade!
Vote.auto_upgrade!


get '/' do
	erb :home
	


end

get '/home' do
	puts session[:user_id]
	
	if session[:user_id]
		todos = Todo.all
		erb :index, :locals => {:todos => todos, :user_id => session[:user_id]}
	else
		redirect '/'
	end
end

post '/create_task' do
	if session[:user_id]
		task = params[:task]
		Todo.create(:task => task, :done => false, :upvotes => 0, :user_id => session[:user_id])
		redirect '/home'
	else
		redirect '/signup'
	end


end

post '/upvote' do
	task_id = params[:task_id]
	user_id = params[:user_id]
	upvotes = params[:upvotes]
	todo = Todo.get(task_id)

	entry = Vote.first({:todo_id => task_id, :user_id => user_id})
	if entry
		if entry.vote
			entry.vote = !entry.vote
			todo.upvotes = todo.upvotes - 1
			todo.save

			
		else
			entry.vote = !entry.vote
			todo.upvotes = todo.upvotes + 1
			todo.save
		end
	else
		entry = Vote.create(:todo_id => task_id, :user_id => user_id, :vote => true)
		todo.upvotes = todo.upvotes + 1
		todo.save
	end

	redirect '/home'

end

get '/login' do
	erb :login
end

get '/signup' do
	erb :signup
end

post '/session_new' do
	name = params[:name]
	email = params[:email]
	username = params[:username]
	password = params[:password]
	cpassword = params[:cpassword]
	user = User.first({:username => username, :email=>email})
	if user
		if user.password == password
			
			puts "setting session user id to", user.id
			session[:user_id] = user.id
			redirect '/home'

		else
			redirect '/login'
		end
	else
		if password == cpassword
		user = User.create(:name => name, :email => email, :username => username, :password => password)
		session[:user_id] = user.id
		redirect '/login'
		else
			erb :password


	end
end
end

post '/session' do
	username = params[:username]
	password = params[:password]
	user = User.first({:username => username})
	if user
		if user.password == password
			puts "setting session user id to", user.id
			session[:user_id] = user.id
			redirect '/home'
		else
			redirect '/login'
		end
	else
		redirect '/signup'
	end
end



get '/logout' do
	session[:user_id] = nil
	redirect '/home'
end


