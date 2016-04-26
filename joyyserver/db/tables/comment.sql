CREATE TABLE comment (
    id             BIGSERIAL  PRIMARY KEY,
    owner          BIGINT        NOT NULL,  -- the id of the person who submitted this comment
    post           BIGINT        NOT NULL,  -- the id of the post this comment is against
    content        TEXT          NOT NULL,
    ct             BIGINT        NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX comment_owner_index ON comment (owner);
CREATE INDEX comment_post_index  ON comment (post);


