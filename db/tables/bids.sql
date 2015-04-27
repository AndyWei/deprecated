CREATE TABLE bids (
    id             BIGSERIAL  PRIMARY KEY,
    bidder_id      BIGINT        NOT NULL,  -- the id of the user who offered this bid
    order_id       BIGINT        NOT NULL,  -- the id of the order
    price          NUMERIC(11,2) NOT NULL,  -- the price that bidder_id wants
    status         SMALLINT      NOT NULL DEFAULT 0,  -- 0-active, 1-accepted, 10-rejected, 20-revoked 
    note           TEXT          NOT NULL,  -- the description provided by the bidder_id
    expire_at      BIGINT        NOT NULL DEFAULT 0,  -- the time when this bid will be expired. It's value in form of the seconds since 1/1/2001. 0 means never expire.
    created_at     TIMESTAMPTZ   NOT NULL,
    updated_at     TIMESTAMPTZ   NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

    CHECK (price >= 0),
    CHECK (status >= 0),

    FOREIGN KEY (bidder_id) REFERENCES users(id),
    FOREIGN KEY (order_id)  REFERENCES orders(id)
);

CREATE INDEX bids_bidder_id_index ON bids (bidder_id);

CREATE INDEX bids_order_id_index ON bids (order_id);
