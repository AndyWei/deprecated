CREATE TABLE users (
    id                 BIGSERIAL  PRIMARY KEY,
    username           TEXT          NOT NULL,  -- when user signup, this field is generated automatically, and the user can modify it later
    password           TEXT          NOT NULL,  -- bcrypt hashed password, it always 60 bytes, however TEXT makes it flexible
    email              TEXT          NOT NULL,  -- user use email to signup and signin
    gender             CHAR(1)       NOT NULL DEFAULT 'm',  -- 'm': male, 'f': famale, 'o': other
    currency           CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country            CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    joyyor_status      SMALLINT      NOT NULL DEFAULT 0,  -- 0 - no joyyor account, 1 - unverified account, 2 - verified individual, 3 - verified company
    assistant          BOOLEAN       NOT NULL DEFAULT false,
    escort             BOOLEAN       NOT NULL DEFAULT false,
    massage            BOOLEAN       NOT NULL DEFAULT false,
    performer          BOOLEAN       NOT NULL DEFAULT false,
    rating             NUMERIC(3)    NOT NULL DEFAULT 420, -- rating = 100 * rating_total / rating_count. It's used to as sorting criterion
    rating_total       NUMERIC(9)    NOT NULL DEFAULT 0,
    rating_count       NUMERIC(6)    NOT NULL DEFAULT 0,
    invite_count       NUMERIC(9)    NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,
    violation_code     SMALLINT              , -- reserved for joyy policy violation code
    display_name       TEXT                  ,
    age                NUMERIC(3)            ,
    bio                TEXT                  ,
    pp_url             TEXT                  , -- the url of the profile photo
    hourly_rate        NUMERIC(7)            , -- the hourly rate that the joyyor asks. In cents.
    coordinate         GEOMETRY(Point, 4326) , -- the point where the joyyor last reported

    UNIQUE (username),

    CHECK (hourly_rate >= 0),
    CHECK (joyyor_status >= 0)
);


CREATE INDEX users_rating_index     ON users (rating);
CREATE INDEX users_coordinate_index ON users USING gist(coordinate);

/* To reduce index size, we don't use UNIQUE constraint on email field. In stead, we created a expression index that
 * only indexes the account part of an email address, which could make the email index about 50% smaller.
 */
CREATE INDEX users_email_index ON users (split_part(email, '@', 1));
