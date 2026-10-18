#!/bin/bash

secret_number=$((RANDOM % 1000 + 1))
number_of_guesses=0

echo "Enter your username:"
if ! read -r username; then
  exit 0
fi

user_data=$(printf "%s\n" "SELECT games_played || '|' || COALESCE(best_game::text, '') FROM users WHERE username = :'username';" | psql --username=freecodecamp --dbname=number_guess -t --no-align -v ON_ERROR_STOP=1 -v "username=$username")

if [[ -z $user_data ]]; then
  echo "Welcome, $username! It looks like this is your first time here."
  printf "%s\n" "INSERT INTO users (username) VALUES (:'username');" | psql --username=freecodecamp --dbname=number_guess -q -v ON_ERROR_STOP=1 -v "username=$username" >/dev/null
else
  IFS='|' read -r games_played best_game <<< "$user_data"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"
if ! read -r guess; then
  exit 0
fi

while true; do
  if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    number_of_guesses=$((number_of_guesses + 1))
    if [[ $guess =~ ^- ]]; then
      guess_value=$((-10#${guess#-}))
    else
      guess_value=$((10#$guess))
    fi

    if (( guess_value == secret_number )); then
      printf "%s\n" "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR :guesses < best_game THEN :guesses ELSE best_game END WHERE username = :'username';" | psql --username=freecodecamp --dbname=number_guess -q -v ON_ERROR_STOP=1 -v "username=$username" -v "guesses=$number_of_guesses" >/dev/null
      echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
      break
    elif (( guess_value > secret_number )); then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi

  if ! read -r guess; then
    break
  fi
done