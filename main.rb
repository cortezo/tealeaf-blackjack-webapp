require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie,  :key => 'rack.session',
                            :path => '/',
                            :secret => 'much_secret_very_wow'

BLACKJACK_AMOUNT = 21
DEALER_MINIMUM = 17

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
    if card_values.reduce(:+) > BLACKJACK_AMOUNT && card_values.include?(11)
      loop do
        card_values[card_values.find_index(11)] = 1
        break if card_values.reduce(:+) <= BLACKJACK_AMOUNT || !card_values.include?(11)
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

    "<img class='card' src='/images/cards/#{suit}_#{rank}.jpg'>"
  end

  def get_winner_message
    @show_hit_and_stand_buttons = false
    @show_dealer_hit_button = false

    player_score = hand_value(session[:player_cards])
    dealer_score = hand_value(session[:dealer_cards])

    # Clear all error messages to display only victory message.
    @error = nil
    @success = nil
    @info = nil

    if player_score > BLACKJACK_AMOUNT
      @error = "#{session[:player_name]} has busted with #{player_score}.  You lose!"
    elsif dealer_score > BLACKJACK_AMOUNT
      @success = "Dealer has busted with #{dealer_score}.  You win!"
    elsif player_score == dealer_score
      @info = "Dealer and #{session[:player_name]} tie with #{player_score}.  Push!"
    elsif player_score > dealer_score
      @success = "#{session[:player_name]} wins with #{player_score}!"
    else
      @error = "Dealer wins with #{dealer_score}!"
    end
  end

  def blackjack?
    # It is only a Blackjack! if it is 21 with two cards, otherwise it is simply a score of 21.
    if session[:player_cards].count > 2 || session[:dealer_cards].count >2
      return false
    end

    player_score = hand_value(session[:player_cards])
    dealer_score = hand_value(session[:dealer_cards])

    if player_score == BLACKJACK_AMOUNT && dealer_score == BLACKJACK_AMOUNT
      @info = "Dealer and #{session[:player_name]} both got Blackjack!  Push!"
      true
    elsif player_score == BLACKJACK_AMOUNT
      @success = "#{session[:player_name]} got Blackjack!  You win!"
      true
    elsif dealer_score == BLACKJACK_AMOUNT
      @error = "Dealer got Blackjack.  You lose!"
      true
    else
      false
    end
  end
end

#####################################################
####################   Before do  ###################
#####################################################
before do
  @show_hit_and_stand_buttons = true
  @show_dealer_hit_button = false
  @show_dealer_hand = false
  @show_play_again_button = false
end

#####################################################
#################### HTML Methods ###################
#####################################################

####### GET Methods #######
get '/' do
  if session[:initialized == true]
    erb :game
  else
    redirect '/set_player'
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

    # Deal initial cards
    session[:dealer_cards] = []
    session[:player_cards] = []
    2.times do
      session[:dealer_cards] << session[:deck].pop
      session[:player_cards] << session[:deck].pop
    end

    if blackjack?
      redirect '/game/compare'
    end

    session[:initialized] = true
  end

  erb :game
end

get '/game/dealer' do
  @show_hit_and_stand_buttons = false
  @show_dealer_hand = true

  dealer_total = hand_value(session[:dealer_cards])

  if dealer_total > BLACKJACK_AMOUNT
    redirect '/game/compare'
  elsif dealer_total >= DEALER_MINIMUM
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end

get '/game/compare' do
  @show_hit_and_stand_buttons = false
  @show_dealer_hand = true
  @show_play_again_button = true

  if blackjack? == false
    get_winner_message
  end

  erb :game
end

####### POST Methods #######
post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required.  Please enter a name."
    halt erb(:new_user_form)
  elsif params[:player_name].match(/\d/)
    @error = "Digits are not allowed.  Please enter a name without digits."
    halt erb(:new_user_form)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

post '/player/hit' do
  session[:player_cards] << session[:deck].pop

  if hand_value(session[:player_cards]) > BLACKJACK_AMOUNT
    halt redirect '/game/compare'
  end

  erb :game
end

post '/player/stand' do
  @success = "#{session[:player_name]} stands."
  redirect '/game/dealer'   
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

post '/startover' do
  session[:initialized] = false
  redirect '/set_player'
end

post '/play_again' do
  session[:initialized] = false
  redirect '/game'
end

post '/game_over' do
  session[:initialized] = false
  erb :game_over
end