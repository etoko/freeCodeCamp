CREATE DATABASE number_guess;
\c number_guess
CREATE TABLE users(
  username VARCHAR(22) PRIMARY KEY,
  games_played INT DEFAULT 0,
  best_game INT
);
