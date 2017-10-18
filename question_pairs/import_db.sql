DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE  questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL

  -- FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  subject_question_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  parent_reply INTEGER NOT NULL,
  author_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  liked_question_id INTEGER NOT NULL
);

INSERT INTO
  users (fname,lname)
VALUES
  ('Steve','Stevens'),
  ('John','Johnson');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('How to know the weather', 'How do you know its cold', (SELECT id FROM users WHERE fname = 'Steve')),
  ('Where am I', 'Help', (SELECT id FROM users WHERE fname = 'John'));

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'John'), (SELECT id FROM questions WHERE title = 'How to know the weather'));
