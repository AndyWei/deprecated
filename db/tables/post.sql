CREATE TABLE post
(
    -- Original fields creted in POST post
    id                 BIGSERIAL  PRIMARY KEY,
    owner              BIGINT        NOT NULL, -- the person.id of the owner who created this post
    url                TEXT          NOT NULL, -- the url of the image. E.g., "post.joyyapp.com/j0176_458354045799.jpg"
    caption            TEXT          NOT NULL, -- the text of the post
    zip                TEXT          NOT NULL, -- the combined zipcode where the post is in. The format is CountryCode + OriginalZipcode. E.g. "US94555"
    -- Social fields
    lcnt               INTEGER               , -- the number of likes
    ccnt               INTEGER               , -- the number of comments
    -- Management fields
    ct                 BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX post_owner_index  ON post (owner);
CREATE INDEX post_ct_index     ON post (ct);
