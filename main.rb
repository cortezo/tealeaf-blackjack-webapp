require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'much_secret_very_wow'

get '/' do
  if session['username']
    redirect :game
  else
    redirect :set_player
  end
end

get '/game' do
  @username = session['username']
  erb :game
end

get '/set_player' do
  erb :set_user_form
end

post '/set_username' do
  session['username'] = params['username']
  redirect :game
end