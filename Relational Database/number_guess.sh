#!/bin/bash

PSQL="psql -X --username=postgres --dbname=number_guess --no-align --tuples-only -c"

# Generate random number between 1-1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
ATTEMPTS=0

# Welcome message
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_ID=$($PSQL "SELECT username FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
else
  # Returning user - get their stats
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")
  echo "Welcome back, $USERNAME! You've played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Game loop
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS

  # Validate input
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, try again:"
    continue
  fi

  ((ATTEMPTS++))

  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $ATTEMPTS tries. The number was $SECRET_NUMBER. Nice job!"

    # Update database
    if [[ -z $USER_ID ]]
    then
      # First game for new user
      UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$ATTEMPTS WHERE username='$USERNAME'")
    else
      # Update existing user
      NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
      if [[ -z $BEST_GAME ]] || [[ $ATTEMPTS -lt $BEST_GAME ]]
      then
        UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$ATTEMPTS WHERE username='$USERNAME'")
      else
        UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE username='$USERNAME'")
      fi
    fi

    break
  fi
done
