DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS question_like;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;


PRAGMA foreign_keys = ON;
CREATE TABLE users(
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions(
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows(
    id INTEGER PRIMARY KEY,
    users_id INTEGER NOT NULL,
    questions_id INTEGER NOT NULL,

    FOREIGN KEY (users_id) REFERENCES users(id),
    FOREIGN KEY (questions_id) REFERENCES questions(id)
);

CREATE TABLE replies(
    id INTEGER PRIMARY KEY,
    body TEXT NOT NULL,
    parent_id INTEGER,
    author_id INTEGER NOT NULL,
    questions_id INTEGER NOT NULL,

    FOREIGN KEY (questions_id) REFERENCES questions(id),
    FOREIGN KEY (parent_id) REFERENCES replies(id),
    FOREIGN KEY (author_id) REFERENCES users(id) 
);

CREATE TABLE question_like(
    id INTEGER PRIMARY KEY,
    questions_id INTEGER NOT NULL,
    users_id INTEGER NOT NULL,

    FOREIGN KEY (questions_id) REFERENCES questions(id),
    FOREIGN KEY (users_id) REFERENCES  users(id)
);

INSERT INTO
    users(fname, lname)
VALUES
    ('Alan', 'Tran-kiem'),
    ('Daniel', 'Lien'),
    ('James', 'Bond');

INSERT INTO
    questions(title, body, author_id)
VALUES
    ('bro', 'do you even lift?', 1),
    ('dude', 'what is lift?', 2),
    ('adivce', 'Why is it that people who can’t take advice always insist on giving it?', 3),
    ('martini', 'shaken or stirred?', 3);

INSERT INTO
    question_follows(users_id, questions_id)
VALUES
    (1,2),
    (1,3),
    (2,4),
    (2,3),
    (3,1);

INSERT INTO
    replies(body,parent_id,questions_id,author_id)
VALUES
    ('hell yeah', NULL, 1, 2),
    ('thats that good good stuff', 1, 1, 1),
    ('that is some good advice', NULL, 3, 3);

INSERT INTO 
    question_like(questions_id, users_id)
VALUES
    (1,2),
    (1,3),
    (2,1),
    (3,3),
    (4,1),
    (4,2),
    (4,3);

