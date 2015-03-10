/* Delete all the tables and data contained, then we'll make 'joyy' a virgin DB */
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public IS 'standard public schema';


/* Create users table and insert test data */
CREATE TABLE users (
    id            BIGSERIAL  PRIMARY KEY,
    username      TEXT          NOT NULL,  -- when user signup, this field is generated automatically, and the user can modify it later
    password      TEXT          NOT NULL,  -- bcrypt hashed password, it always 60 bytes, however TEXT provides flexible
    email         TEXT          NOT NULL,  -- user use email to signup
    role          SMALLINT      NOT NULL,  -- 1-user, 2-admin, 3-test, 4-robot
    status        SMALLINT      NOT NULL DEFAULT 1,  -- 1-active, 2-closed, 3-suspended
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    deleted       BOOLEAN       NOT NULL DEFAULT FALSE,
    rating        NUMERIC(2,1)          ,
    rating_count  NUMERIC(6)            ,
    bio           VARCHAR(100)
);

INSERT INTO users
    (     username,                                                    password,                 email, role, status, created_at, updated_at, deleted) VALUES
    (         'jac', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'jac.david@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (        'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com',    1,      1,      now(),      now(),   FALSE);





/* Create orders table and insert test data */
CREATE TABLE orders (
    id            BIGSERIAL  PRIMARY KEY,
    price         NUMERIC(12,2) NOT NULL,
    currency      CHAR(3)       NOT NULL,  -- ISO 4217 Currency Codes
    status        SMALLINT      NOT NULL,  -- 1-active, 2-closed, 3-pending, 4-canceled
    created_by    BIGINT        NOT NULL,  -- the user id who created this order
    winner_id     BIGINT                ,  -- the user id who wins this order
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    deleted       BOOLEAN       NOT NULL,
    description   VARCHAR(1000) NOT NULL
);

INSERT INTO orders
    (        price, currency, status, created_by, created_at, updated_at, deleted, description) VALUES
    (         9.99,    'USD',      1,         1,       now(),      now(),   FALSE, 'jumpstart'),
    (        89.99,    'USD',      2,         1,       now(),      now(),    TRUE, 'house clean'),
    (1234567890.99,    'RMB',      3,         1,       now(),      now(),   FALSE, 'ride');
