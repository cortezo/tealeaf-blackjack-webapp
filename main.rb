require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'much_secret_very_wow'

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    session[:initialized] = false
    redirect '/set_player'
  end
end

get '/game' do

  if session[:initialized] == false
    # create a deck and put it in the session
    suits = ['H', 'D', 'C', 'S']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(values).shuffle! #[ ['H', '2'], ['H', '3'], ...etc]
    
    # deal cards
      #dealer cards, player cards
    session[:dealer_cards] = []
    session[:player_cards] = []
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop

    session[:initialized] = true
  end

  if session[:player_hit?] == true
    session[:player_cards] << session[:deck].pop
    session[:player_hit?] = false
  elsif session[:player_stand?] == true
    # start dealer turn
  else

  end

  erb :game
end

get '/set_player' do
  erb :new_user_form
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/bet' do
  @player_name = session[:player_name]
end

post '/hit' do
  session[:player_hit?] = true
  redirect '/game'
end

post '/stand' do
  session[:player_stand?] = true
  redirect '/game'
end

get '/startover' do
  session[:player_name] = nil
  session[:initialized] = false
  redirect '/'
end