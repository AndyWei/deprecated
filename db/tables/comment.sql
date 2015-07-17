CREATE TABLE comment (
    id             BIGSERIAL  PRIMARY KEY,
    owner_id       BIGINT        NOT NULL,  -- the id of the person who submitted this comment
    media_id       BIGINT        NOT NULL,  -- the id of the media this comment is against
    content        TEXT          NOT NULL,
    created_at     TIMESTAMPTZ   NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX comment_owner_id_index ON comment (owner_id);

CREATE INDEX comment_media_id_index ON comment (media_id);


