\ir  setup.sql


INSERT INTO person
    (username,                                                       password,         phone,         org,     cell, verified, gender,  yob, hearts,   score,            ct,            ut, coords) VALUES
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',   14257850318,   'twitter',  '94555',     true,      1, 1980,      1,       5, 1437524632001, 1437524632001, ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',   14256287208,      'joyy',  '94555',     true,      2, 1988,    235,       5, 1437524632002, 1437524632002, ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    ( 'tiger', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',   18008888756,      'joyy',  '94555',     true,      1, null,      1,    1155, 1437524632003, 1437524632003, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    ('jayden', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',   18004933316,      'joyy',  '94102',     true,      1, null,      1,       5, 1437524632004, 1437524632004, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'moon', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',   18882450625,    'goooog',  '94555',     true,      0, null,      0,       0, 1437524632001, 1437524632001, ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (  'sky1', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 8613980796531,    'goooog',  '94555',     true,      0, null,      0,       0, 1437524632002, 1437524632002, ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (  'sun2', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',   18009971468,    'appple',  '94555',     true,      0, null,      0,       0, 1437524632003, 1437524632003, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (  'mini', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 8613308000897,    'joyyyy',  '94102',     true,      3, null, 342718, 1500000, 1437524632004, 1437524632004, ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));


INSERT INTO post
    (owner,                 filename,                      caption,            ct,    cell, coords) VALUES
    (    1, 'j5676_462931203926.jpg',   'Open!!!!',                 1437524632000, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j6575_462929722813.jpg',   'DREAM',                    1437524632001, '94102', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j0000_458440716099.jpg',   'HOPE',                     1437524632002, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j4403_462934349762.jpg',   'It is hard',               1437524632003, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j2552_458446437154.jpg',   'maybe the best of things', 1437524632004, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j2387_458461122798.jpg',   'Leonardo da Vinci',        1437524632005, '94102', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326)),
    (    1, 'j3844_461624043152.jpg',   'Take off',                 1437524632006, '94555', ST_SetSRID(ST_MakePoint(-122.062175637225, 37.5584115414299), 4326));


INSERT INTO comment
    ( post, owner,            ct, content) VALUES
    (    1,     2, 1437524632001, 'How many girlfriends?'),
    (    1,     3, 1437524632002, 'Whats up?'),
    (    1,     4, 1437524632003, 'The quick brown fox jumps over the lazy dog. '),
    (    1,     1, 1437524632004, 'Leonardo di ser Piero da Vinci, more commonly Leonardo da Vinci, (15 April 1452 – 2 May 1519) was an Italian polymath. His areas of strength included painting, sculpting, architecture, science, music, mathematics, engineering, invention, anatomy, geology, astronomy, botany, writing, history, and cartography.'),
    (    2,     2, 1437524632005, 'So we beat on, boats against the current, borne back ceaselessly into the past.'),
    (    2,     3, 1437524632006, 'The knife came down, missing him by inches, and he took off.'),
    (    2,     4, 1437524632007, 'What are u talking about?'),
    (    2,     1, 1437524632008, 'Remember Red, hope is a good thing, maybe the best of things, and no good thing ever dies.');


INSERT INTO heart
    (sender, receiver, status,            ct,            ut) VALUES
    (     4,        1,     20, 1437524632001, 1437524632001),
    (     3,        1,     20, 1437524632002, 1437524632002),
    (     2,        1,     20, 1437524632003, 1437524632003),
    (     2,        1,     20, 1437524632004, 1437524632004),
    (     4,        2,      0, 1437524632005, 1437524632005),
    (     3,        2,      0, 1437524632006, 1437524632006),
    (     1,        2,      0, 1437524632007, 1437524632007),
    (     1,        2,      0, 1437524632008, 1437524632008),
    (     4,        1,      0, 1437524632009, 1437524632009),
    (     3,        1,      0, 1437524632010, 1437524632010),
    (     2,        1,      0, 1437524632020, 1437524632020),
    (     2,        1,      0, 1437524632030, 1437524632030);
