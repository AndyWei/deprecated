CREATE TABLE invite (
    id                 BIGSERIAL  PRIMARY KEY,
    user_id            BIGINT        NOT NULL,  -- the id of the customer who placed this invite
    invitee_id         BIGINT[]      NOT NULL,  -- the array of invited joyyor user_ids
    duration           NUMERIC(2)    NOT NULL,  -- the duration that the customer wants. In hours.
    currency           CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country            CHAR(2)       NOT NULL DEFAULT 'us',   -- country code
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-active, 10-accepted, 20-started, 30-finished, 40-paid, 50-refunded
    category           SMALLINT      NOT NULL DEFAULT 0,  -- the service category: 0-none, 1-assistant, 2-escort, 3-massage, 4-performer
    title              TEXT          NOT NULL,
    start_time         BIGINT        NOT NULL,
    coordinate         GEOMETRY(Point, 4326) NOT NULL,  -- the coordinate of the place where the customer wants to be served. It's used for searching and calculating distance
    city               TEXT          NOT NULL,  -- the city name of coordinate
    address            TEXT          NOT NULL,  -- the full address of coordinate
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,
    finished_at        TIMESTAMPTZ           ,  -- the timestamp of finished the invite
    winner_id          BIGINT                ,  -- the user_id of the joyyor who won this invite
    winner_name        TEXT                  ,  -- the display_name of the joyyor who won this invite.
    final_price        NUMERIC(10)           ,  -- final_price = duration * joyyor.hourly_rate. In cents.
    stripe_token       TEXT                  ,  -- the string that represents a credit card (start with tok_ ) or a stripe customer object (start with cus_ )
    stripe_charge_id   TEXT                  ,  -- the string that represents a sucessful charge, which will be used for refund
    stripe_refund_id   TEXT                  ,  -- the string that represents a sucessful refund, which will be used for tracking purpose


    CHECK (duration >= 0),
    CHECK (final_price >= 0),
    CHECK (status >= 0),
    CHECK (category >= 0),

    FOREIGN KEY (user_id)   REFERENCES jyuser(id),
    FOREIGN KEY (winner_id) REFERENCES jyuser(id)
);


CREATE INDEX invite_user_id_index ON invite (user_id);

/* partial index on not null winner_id only, which is to reduce index size */
CREATE INDEX invite_winner_id_index ON invite (winner_id) WHERE winner_id IS NOT NULL;

CREATE INDEX invite_coordinate_index ON invite USING gist(coordinate);
