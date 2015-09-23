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

  def distribute_winnings(result)
    if result == "win"
      session[:player_cash] += session[:current_bet] * 2
    elsif result == "blackjack"
      session[:player_cash] += session[:current_bet] * 2.5
    elsif result == "push"
      session[:player_cash] += session[:current_bet]
    end

    # Reset current_bet to zero to prevent abuse by reloading /game/compare page.
    session[:current_bet] = 0
  end


  def get_winner_message
    player_score = hand_value(session[:player_cards])
    dealer_score = hand_value(session[:dealer_cards])

    # Clear all error messages to display only victory message.
    @tie = nil
    @winner = nil
    @loser = nil

    if session[:blackjack?]
      if player_score == dealer_score
        @tie = "Dealer and #{session[:player_name]} both got Blackjack!  Push!"
        distribute_winnings("push")
      elsif player_score == BLACKJACK_AMOUNT
        @winner = "#{session[:player_name]} got Blackjack!  You win $#{session[:current_bet] * 2.5}!"
        distribute_winnings("blackjack")
      elsif dealer_score == BLACKJACK_AMOUNT
        @loser = "Dealer got Blackjack.  You lose $#{session[:current_bet]}."
      end
    elsif player_score > BLACKJACK_AMOUNT
      @loser = "#{session[:player_name]} has busted with #{player_score}.  You lose $#{session[:current_bet]}!"
    elsif dealer_score > BLACKJACK_AMOUNT
      @winner = "Dealer has busted with #{dealer_score}.  You win $#{session[:current_bet] * 2}!"
      distribute_winnings("win")
    elsif player_score == dealer_score
      @tie = "Dealer and #{session[:player_name]} tie with #{player_score}.  Push!"
      distribute_winnings("push")
    elsif player_score > dealer_score
      @winner = "#{session[:player_name]} wins with #{player_score}!  You win $#{session[:current_bet] * 2}!"
      distribute_winnings("win")
    else
      @loser = "Dealer wins with #{dealer_score}!  You lose $#{session[:current_bet]}."
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
  if session[:initialized]
    erb :game
  else
    redirect '/set_player'
  end
end

get '/set_player' do
  session[:initialized] = false
  erb :new_user_form
end

get '/bet' do
  if session[:player_cash] <= 0
    @display_start_over_button = true
  end

  erb :bet
end

get '/game' do

  if !session[:initialized]
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

    session[:blackjack?] = false

    # REVISIT... possibly confusing use of variable names
    if hand_value(session[:dealer_cards]) == BLACKJACK_AMOUNT || hand_value(session[:player_cards]) == BLACKJACK_AMOUNT
      session[:blackjack?] = true
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
  @show_dealer_hit_button = false
  @show_dealer_hand = true
  @show_play_again_button = true

  get_winner_message

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

  session[:player_cash] = 1000
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

post '/player/hit' do
  session[:player_cards] << session[:deck].pop

  if hand_value(session[:player_cards]) > BLACKJACK_AMOUNT
    halt redirect '/game/compare'
  end

  redirect '/game'
end

post '/player/stand' do
  @success = "#{session[:player_name]} stands."
  redirect '/game/dealer'   
end

post '/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

post '/player/bet' do
  bet_amount = params[:bet_amount].to_i

  if params[:bet_amount].match(/\D/)
    @error = "Your entry contained a non-digit character.  Please enter a valid bet by entering a whole number greater than zero and less than or equal to your available cash."
    halt erb(:bet)
  elsif bet_amount.to_i <= 0
    @error = "Your entry must be greater than zero.  Please enter a valid bet by entering a whole number greater than zero and less than or equal to your available cash."
    halt erb(:bet)
  elsif bet_amount > session[:player_cash]
    @error = "You don't have that much money to bet.  Please enter a valid bet by entering a whole number greater than zero and less than or equal to your available cash."
    halt erb(:bet)
  else
    session[:current_bet] = bet_amount
    session[:player_cash] -= bet_amount
  end

  redirect '/game'
end

post '/startover' do
  session[:initialized] = false
  redirect '/set_player'
end

post '/play_again' do
  session[:initialized] = false
  redirect '/bet'
end

post '/game_over' do
  session[:initialized] = false
  erb :game_over
end