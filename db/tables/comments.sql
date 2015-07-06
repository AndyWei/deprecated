CREATE TABLE comments (
    id             BIGSERIAL  PRIMARY KEY,
    user_id        BIGINT        NOT NULL,  -- the id of the user who submitted this comment
    username       TEXT          NOT NULL,  -- denormalized design, has username here to avoid join
    order_id       BIGINT        NOT NULL,  -- the id of the order
    body           TEXT          NOT NULL,
    created_at     TIMESTAMPTZ   NOT NULL,
    updated_at     TIMESTAMPTZ   NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

    FOREIGN KEY (user_id)  REFERENCES jyuser(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);


CREATE INDEX comments_user_id_index ON comments (user_id);

CREATE INDEX comments_order_id_index ON comments (order_id);


