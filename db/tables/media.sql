CREATE TABLE media (
    id                 BIGSERIAL  PRIMARY KEY,
    owner_id           BIGINT        NOT NULL,  -- the person.id of the owner who uploaded this media
    coordinate         GEOMETRY(Point, 4326) NOT NULL,  -- the coordinate of the place where the media was uploaded. It's used for searching
    media_type         SMALLINT      NOT NULL DEFAULT 0,  -- the media category: 0-photo, 1-video, 2-audio
    path_version       SMALLINT      NOT NULL DEFAULT 0,  -- the version number of the file path. Client will map this number to the base_url. 0-Amazon CloudFront
    filename           TEXT          NOT NULL,  -- the file name without path. e.g., j0176_458354045799.jpg
    caption            TEXT          NOT NULL,
    created_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX media_owner_id_index ON media (owner_id);
CREATE INDEX media_coordinate_index ON media USING gist(coordinate);

/* Note: the media url = base_url + filename, where the base_url is decoded from path_version
 * Use this way instead of storing the whole url is to:
 *   1. save some space by avoiding store base_url for every record
 *   2. in case we need to keep the existing media files on S3 but store new ones at somewhere else, we can just use another path_version value for the
 *   new place and the client can handle both old and new urls gracefully
*/