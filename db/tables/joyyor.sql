CREATE TABLE joyyor (
    id                 BIGSERIAL  PRIMARY KEY,
    user_id            BIGINT        NOT NULL,
    display_name       TEXT          NOT NULL,
    gender             CHAR(1)       NOT NULL,  -- 'm': male, 'f': famale, 'o': other
    hourly_rate        NUMERIC(7)    NOT NULL,  -- the hourly rate that the joyyor asks. In cents.
    currency           CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country            CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-active. values greater than 100 are reserved for all kinds of joyy policy violation code
    assistant          BOOLEAN       NOT NULL DEFAULT false,
    escort             BOOLEAN       NOT NULL DEFAULT false,
    massage            BOOLEAN       NOT NULL DEFAULT false,
    performer          BOOLEAN       NOT NULL DEFAULT false,
    rating             NUMERIC(3)    NOT NULL DEFAULT 420, -- rating = 100 * rating_total / rating_count. It's used to as sorting criterion
    rating_total       NUMERIC(9)    NOT NULL DEFAULT 0,
    rating_count       NUMERIC(6)    NOT NULL DEFAULT 0,
    invite_count       NUMERIC(9)    NOT NULL DEFAULT 0,
    coordinate         GEOMETRY(Point, 4326)   NOT NULL,   -- the point where the joyyor last reported
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,
    age                NUMERIC(3)            ,
    bio                TEXT                  ,
    ppurl              TEXT                  ,

    CHECK (hourly_rate >= 0),
    CHECK (status >= 0)
);


CREATE INDEX joyyor_user_id_index    ON joyyor (user_id);
CREATE INDEX joyyor_rating_index     ON joyyor (rating);
CREATE INDEX joyyor_coordinate_index ON joyyor USING gist(coordinate);
