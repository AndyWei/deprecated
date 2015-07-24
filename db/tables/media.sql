CREATE TABLE media (
    id                 BIGSERIAL  PRIMARY KEY,
    owner              BIGINT        NOT NULL,  -- the person.id of the owner who uploaded this media
    type               SMALLINT      NOT NULL DEFAULT 0,  -- the media type: 0-photo, 1-video, 2-audio
    uv                 SMALLINT      NOT NULL DEFAULT 0,  -- the url version of the media file. Client will map this number to the base_url. 0-KeyCDN
    filename           TEXT          NOT NULL,  -- the file name without suffix. e.g., j0176_458354045799
    caption            TEXT          NOT NULL,
    cell               TEXT          NOT NULL, -- the cell where the media belongs to
    coords             GEOMETRY(Point, 4326) NOT NULL,  -- the coordinate of the place where the media was uploaded. It's used for searching
    likes              INTEGER       NOT NULL DEFAULT 0, -- the number of likes
    comments           INTEGER       NOT NULL DEFAULT 0, -- the number of comments
    ct                 BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX media_owner_index  ON media (owner);
CREATE INDEX media_ct_index     ON media (ct);

/* Note: the media url = base_url + filename, where the base_url is decoded from uv
 * Use this way instead of storing the whole url is to:
 *   1. save some space by avoiding store base_url for every record
 *   2. in case we need to keep the existing media files on S3 but store new ones at somewhere else, we can just use another uv value for the
 *   new place and the client can handle both old and new urls gracefully
*/