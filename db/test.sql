/* Delete all the tables and data contained, then we'll make 'joyy' a virgin DB */
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
COMMENT ON SCHEMA public IS 'standard public schema';

/* Enable PostGIS*/
CREATE EXTENSION postgis;


/* Create users table and insert test data */
CREATE TABLE users (
    id            BIGSERIAL  PRIMARY KEY,
    username      TEXT          NOT NULL,  -- when user signup, this field is generated automatically, and the user can modify it later
    password      TEXT          NOT NULL,  -- bcrypt hashed password, it always 60 bytes, however TEXT provides flexible
    email         TEXT          NOT NULL,  -- user use email to signup
    role          SMALLINT      NOT NULL,  -- 1-user, 2-admin, 3-test, 4-robot
    status        SMALLINT      NOT NULL DEFAULT 1,  -- 0-inactive, 1-active, 2-closed, 3-suspended
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    deleted       BOOLEAN       NOT NULL DEFAULT false,
    rating        NUMERIC(2,1)          ,
    rating_count  NUMERIC(6)            ,
    bio           VARCHAR(100)
);

INSERT INTO users
    (username,                                                       password,                 email, role, status, created_at, updated_at, deleted) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'jack.davi@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'ping@gmail.com',         1,      1,      now(),      now(),   FALSE);





/* Create orders table and insert test data */
CREATE TABLE orders (
    id             BIGSERIAL  PRIMARY KEY,
    uid            BIGINT        NOT NULL,  -- the id of the user who placed this order
    initial_price  NUMERIC(19,2) NOT NULL,  -- the initial price before bidding and negotiation
    currency       CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country        CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    status         SMALLINT      NOT NULL DEFAULT 1,  -- 0-inactive, 1-active, 2-closed, 3-pending, 4-canceled
    category       SMALLINT      NOT NULL DEFAULT 0,  -- the service category: 0-uncategorized, 1-roadside_aid, 2-ride, 3-moving, 4-delivery, 5-cleaning, 6-handyman, 7-assistance
    description    VARCHAR(1000) NOT NULL,
    venue  GEOMETRY(Point, 4326) NOT NULL,  -- the venue where order should be serviced, used for searching and calculating distance
    created_at     TIMESTAMP     NOT NULL,
    updated_at     TIMESTAMP     NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,
    address        TEXT                  ,  -- the address where order should be serviced, used for indicating the service seller
    winner_id      BIGINT                ,  -- the id of the user who wins this order
    final_price    NUMERIC(19,2)             -- the final price after bidding and negotiation
);

INSERT INTO orders
    (uid, winner_id, initial_price,  status, category, created_at, updated_at,  description, venue) VALUES
    (  1,         1,          0.99,       1,        1,      now(),      now(),  'jumpstart', ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  1,         3,         89.99,       2,        5,      now(),      now(),      'clean', ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (  1,         3,     234567.99,       3,        2,      now(),      now(), 'ride to LA', ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));
