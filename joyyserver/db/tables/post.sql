CREATE TABLE post
(
    -- Original fields creted in POST post
    id                 BIGSERIAL  PRIMARY KEY,
    owner              BIGINT        NOT NULL, -- the person.id of the owner who created this post
    reg                CHAR(2)               , -- the photo bucket region of the post media, which will be used to compose the subdomain of the media URL. E.g., 'na', 'eu', 'as'
    fn                 TEXT                  , -- the filename of the media file, which will be used to by client to compose the media file URL
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
