require 'rubygems'
# If you're using bundler, you will need to add this
require 'bundler/setup'
require 'json'
require 'sinatra'

$LOAD_PATH << '.'
require 'grab_dfm'

get '/' do
	'here is the home'
end

get '/hello' do
	content_type :json
	{message: 'hello'}.to_json
end

get	'/liked_songs' do
	content_type :json, 'charset' => 'utf-8'
	user = params['user']
	password = params['password']
	fetch_loved_songs(user,password).to_json
end

get '/download_address' do
	content_type :text, 'charset' => 'utf-8'
	get_download_address params[:song_name]
end
