CREATE TABLE wink (
    id                 BIGSERIAL  PRIMARY KEY,
    sender             BIGINT        NOT NULL,  -- the person.id of sender
    receiver           BIGINT        NOT NULL,  -- the person.id of receiver
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-sent, 10-accepted, 20-rejected
    ct                 BIGINT        NOT NULL,
    ut                 BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX wink_sender_index ON wink (sender);
CREATE INDEX wink_receiver_index ON wink (receiver);

