#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def init_db
	@db = PG.connect('localhost',5432,'','','Leprosorium','postgres','P123#dfr')
end

before do
	init_db
end

configure do
	init_db
	@db.exec %(create table if not exists Posts (
		id	SERIAL PRIMARY KEY,
		created_date	timestamp without time zone,
		content	TEXT
		))
	@db.exec %(create table if not exists Comments (
		id	SERIAL PRIMARY KEY,
		created_date	timestamp without time zone,
		content	TEXT,
		post_id INTEGER
		))
end

get '/' do
	@results = @db.exec "select * from Posts order by id desc"
	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]
	if content.length <= 0
		@error = 'Type post text'
		return erb :new
	end
	@db.exec_params "insert into Posts (content, created_date) values ($1, date_trunc('second', now()::timestamp))",[content]
	redirect to('/')
end

get '/comments/:post_id' do
	post_id = params[:post_id]
	results = @db.exec_params "select * from posts where id = $1",[post_id]
	#results = @db.exec_prepared 'statement2', [post_id]
	@row = results[0]
	@comments = @db.exec_params "select * from comments where post_id = $1",[post_id]
	erb :comments
end

post '/comments/:post_id' do
	post_id = params[:post_id]
	content = params[:content]
	if content.length <= 0
		@error = 'Type post text'
		return erb :comments
	end
	@db.exec_params "insert into Comments (content, created_date, post_id) values ($1, date_trunc('second', now()::timestamp), $2)",[content, post_id]
	redirect to('/comments/' + post_id)
end