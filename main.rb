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

    # Reduce ace value if total is greater than 21
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

    suit = case card[0]
      when "H" then "hearts"
      when "D" then "diamonds"
      when "C" then "clubs"
      when "S" then "spades"
    end

    rank = case card[1]
      when 'J' then "jack"
      when 'Q' then "queen"
      when 'K' then "king"
      when 'A' then "ace"
      when /\d/ then card[1].to_s
    end

    "<img class='card' src='images/cards/#{suit}_#{rank}.jpg'>"
  end

  def get_winner_message
    player_score = hand_value(session[:player_cards])
    dealer_score = hand_value(session[:dealer_cards])

    # Clear all error messages to display only victory message.
    @error = nil
    @success = nil
    @info = nil

    if session[:player_bust?]
      @error = "#{session[:player_name]} has busted.  You lose!"
    elsif session[:dealer_bust?]
      @success = "Dealer has busted.  You win!"
    elsif player_score == dealer_score
      @info = "Dealer and #{session[:player_name]} tie.  Push!"
    elsif player_score > dealer_score
      @success = "#{session[:player_name]} wins!"
    else
      @error = "Dealer wins!"
    end
  end

  def blackjack?
    player_score = hand_value(session[:player_cards])
    dealer_score = hand_value(session[:dealer_cards])

    if player_score == 21 && dealer_score == 21
      @info = "Dealer and #{session[:player_name]} both got Blackjack!  Push!"
      true
    elsif player_score == 21
      @success = "#{session[:player_name]} got Blackjack!  You win!"
      true
    elsif dealer_score == 21
      @error = "Dealer got Blackjack.  You lose!"
      true
    else
      false
    end
  end

  # Moved dealer turn logic from POST dealer_next_card to Helper to allow direct calling from player_stand POST method.
  def dealer_turn
    if hand_value(session[:dealer_cards]) < 17
      session[:dealer_cards] << session[:deck].pop
    end

    if hand_value(session[:dealer_cards]) >= 17 && hand_value(session[:dealer_cards]) <= 21
      session[:game_over?] = true
      get_winner_message
      halt erb(:game)
    elsif hand_value(session[:dealer_cards]) > 21
      session[:dealer_bust?] = true
      session[:game_over?] = true
      get_winner_message
      halt erb(:game)
    end

    erb :game
  end

end

#####################################################
####################   Before do  ###################
#####################################################
before do
  @show_hit_and_stand_buttons = true

  if session[:game_over?] == true
    get_winner_message
  elsif session[:player_stand?] == true && session[:initialized] == true
    @success = "#{session[:player_name]} is standing."
  end
end

#####################################################
#################### HTML Methods ###################
#####################################################

####### GET Methods #######
get '/' do
  if session[:initialized == true]
    erb :game
  else
    redirect :set_player
  end
end

get '/set_player' do
  session[:initialized] = false
  erb :new_user_form
end

get '/game' do

  if session[:initialized] == false
    # Create a deck and put it in the session
    suits = ['H', 'D', 'C', 'S']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(values).shuffle! #[ ['H', '2'], ['H', '3'], ...etc]
    
    # Initialize tracking variables
    session[:player_stand?] = false
    session[:player_bust?] = false
    session[:dealer_bust?] = false
    session[:game_over?] = false

    # Deal initial cards
    session[:dealer_cards] = []
    session[:player_cards] = []
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop

    if blackjack?
      session[:game_over?] = true
      halt erb(:game)
    end

    session[:initialized] = true
  end

  erb :game
end

=begin
get '/bet' do
  @player_name = session[:player_name]
end
=end

####### POST Methods #######
post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required.  Please enter a name."
    halt erb(:new_user_form)
  end

  session[:player_name] = params[:player_name]
  redirect :game
end

post '/player_hit' do
  session[:player_cards] << session[:deck].pop

  if hand_value(session[:player_cards]) > 21
    session[:game_over?] = true
    session[:player_bust?] = true
    get_winner_message
    halt erb(:game)
  end

  erb :game
end

post '/player_stand' do
  session[:player_stand?] = true
  @success = "#{session[:player_name]} is standing."

  # Call helper method directly in order to avoid displaying Next Card button when
  # dealer is not required to hit.
  dealer_turn   
end

post '/dealer_next_card' do
  dealer_turn
end

post '/startover' do
  # Reset trackign variables
  session[:player_stand?] = false
  session[:player_bust?] = false
  session[:dealer_bust?] = false
  session[:game_over?] = false
  session[:initialized] = false

  redirect :set_player
end