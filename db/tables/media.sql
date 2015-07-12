CREATE TABLE media (
    id                 BIGSERIAL  PRIMARY KEY,
    user_id            BIGINT        NOT NULL,  -- the id of the user who uploaded this media
    coordinate         GEOMETRY(Point, 4326) NOT NULL,  -- the coordinate of the place where the media was uploaded. It's used for searching
    media_type         SMALLINT      NOT NULL DEFAULT 0,  -- the media category: 0-photo, 1-video, 2-audio
    path_version       SMALLINT      NOT NULL DEFAULT 0,  -- the version number of the file path. Client will map this number to a url base string. 0-Amazon CloudFront
    filename           TEXT          NOT NULL,  -- the file name without path. e.g., j0176_458354045799.jpg
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,

    FOREIGN KEY (user_id)   REFERENCES jyuser(id)
);


CREATE INDEX media_user_id_index ON media (user_id);
CREATE INDEX media_coordinate_index ON media USING gist(coordinate);
