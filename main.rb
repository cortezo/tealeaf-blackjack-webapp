require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'much_secret_very_wow'

#####################################################
################### Helper Methods ##################
#####################################################
helpers do
  def hand_value(hand)
    card_values = []
    hand.each do |card|
      if card[1].match(/[B-Z]/)
        card_values << 10
      elsif card[1].match("A")
        card_values << 11
      else
        card_values << card[1].to_i
      end
    end

    if card_values.reduce(:+) > 21 && card_values.include?(11)
      loop do
        card_values[card_values.find_index(11)] = 1
        break if card_values.reduce(:+) <= 21 || !card_values.include?(11)
      end
    end
    card_values.reduce(:+)
  end

  def get_card_image(card)
    suit = ""
    rank = ""

    case card[0]
    when "H" then suit = "hearts"
    when "D" then suit = "diamonds"
    when "C" then suit = "clubs"
    when "S" then suit = "spades"
    end

    case card[1]
    when 'J' then rank = "jack"
    when 'Q' then rank = "queen"
    when 'K' then rank = "king"
    when 'A' then rank = "ace"
    when /\d/ then rank = card[1].to_s
    end

    "<img class='card' src='images/cards/#{suit}_#{rank}.jpg'>"
  end
end

#####################################################
#################### HTML Methods ###################
#####################################################
get '/' do
  if session[:initialized == true]
    redirect '/game'
  else
    session[:initialized] = false
    redirect '/set_player'
  end
end

get '/game' do

  if session[:initialized] == false
    # Create a deck and put it in the session
    suits = ['H', 'D', 'C', 'S']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(values).shuffle! #[ ['H', '2'], ['H', '3'], ...etc]
    
    # Initialize tracking variables
    session[:player_bust?] = false
    session[:player_stand?] = false
    session[:player_hand_value] = 0
    session[:dealer_stand?] = false
    session[:dealer_bust?] = false

    # Deal initial cards
    session[:dealer_cards] = []
    session[:player_cards] = []
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop

    session[:initialized] = true
  end

  # Player turn
  if session[:player_hit?] == true
    session[:player_cards] << session[:deck].pop

    if hand_value(session[:player_cards]) > 21
      session[:player_bust?] = true
    end
    session[:player_hit?] = false
  elsif session[:player_stand?] == true
    # Dealer turn
    if hand_value(session[:dealer_cards]) < 17
      session[:dealer_cards] << session[:deck].pop
    elsif hand_value(session[:dealer_cards]) >= 17 && hand_value(session[:dealer_cards]) <= 21
      session[:dealer_stand?] = true
    end

    if hand_value(session[:dealer_cards]) > 21
      session[:dealer_bust?] = true
    end
  else

  end

  session[:player_hand_value] = hand_value(session[:player_cards])

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

post '/startover' do
  session[:initialized] = false
  redirect '/'
end