CREATE TABLE jyuser (
    id                 BIGSERIAL  PRIMARY KEY,
    username           TEXT          NOT NULL,  -- when user signup, this field is generated automatically, and the user can modify it later
    password           TEXT          NOT NULL,  -- bcrypt hashed password, it always 60 bytes, however TEXT makes it flexible
    email              TEXT          NOT NULL,  -- user use email to signup and signin
    gender             TEXT          NOT NULL DEFAULT 'm',  -- 'm': male, 'f': famale, 'o': other
    currency           CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country            CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    joyyor_status      SMALLINT      NOT NULL DEFAULT 0,  -- 0 - no joyyor account, 1 - unverified account, 2 - verified individual, 3 - verified company
    category           SMALLINT      NOT NULL DEFAULT 0,  -- 0 - none, 1 - assistant, 2 - escort, 3 - massage, 4 - performer
    rating             NUMERIC(4)    NOT NULL DEFAULT 4200, -- rating = 1000 * rating_total / rating_count. It's used to as sorting criterion
    rating_total       NUMERIC(9)    NOT NULL DEFAULT 0,
    rating_count       NUMERIC(5)    NOT NULL DEFAULT 0,
    invite_count       NUMERIC(9)    NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,
    violation_code     SMALLINT              , -- reserved for joyy policy violation code
    display_name       TEXT                  ,
    age                NUMERIC(3)            ,
    bio                TEXT                  ,
    portrait_url       TEXT                  , -- the url of the portrait photo
    hourly_rate        NUMERIC(7)            , -- the hourly rate that the joyyor asks. In cents.
    coordinate         GEOMETRY(Point, 4326) , -- the point where the user last reported

    UNIQUE (username),

    CHECK (hourly_rate >= 0),
    CHECK (joyyor_status >= 0)
);


CREATE INDEX jyuser_rating_index     ON jyuser (rating);
CREATE INDEX jyuser_coordinate_index ON jyuser USING gist(coordinate);

/* To reduce index size, we don't use UNIQUE constraint on email field. In stead, we created a expression index that
 * only indexes the account part of an email address, which could make the email index about 50% smaller.
 */
CREATE INDEX jyuser_email_index ON jyuser (split_part(email, '@', 1));
