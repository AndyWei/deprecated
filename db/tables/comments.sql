CREATE TABLE comments (
    id             BIGSERIAL  PRIMARY KEY,
    user_id        BIGINT        NOT NULL,  -- the id of the user who submitted this comment
    username       TEXT          NOT NULL,  -- denormalized design, has username here to avoid join
    order_id       BIGINT        NOT NULL,  -- the id of the order
    is_from_joyyor BOOLEAN       NOT NULL,  -- is this comment from the joyyor app, this field will be used to select push notification app
    to_username    TEXT                  ,  -- NULL if parent_id is 0, otherwise the username of the parent comments
    contents       TEXT          NOT NULL,
    created_at     TIMESTAMPTZ   NOT NULL,
    updated_at     TIMESTAMPTZ   NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

    FOREIGN KEY (user_id)  REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);


CREATE INDEX comments_order_id_index ON comments (order_id);

