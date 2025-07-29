-- users
create table if not exists users (
    id integer primary key autoincrement,
    username text not null unique,
    email text not null unique,
    passwordhash text not null,

    created_at datetime default current_timestamp
);

-- videos
create table if not exists videos (
    id integer primary key autoincrement,
    user_id integer,
    title text not null,
    description text,

    video_bucket TEXT NOT NULL DEFAULT 'videos',
    video_object TEXT NOT NULL,

    thumbnail_bucket TEXT NOT NULL DEFAULT 'thumbnails',
    thumbnail_object TEXT NOT NULL,

    slug text not null unique,

    visibility text not null default 'public' check (visibility in ('public', 'unlisted', 'private')), -- enum ( public | unlisted | private )

    uploaded_at datetime default current_timestamp,

    foreign key (user_id) references users(id) on delete set null
);

-- comments
create table if not exists comments (
    id integer primary key autoincrement,
    video_id integer not null,
    user_id integer not null,
    parent_id integer, -- reply-to : null for top-level comments, otherwise id of the comment being replied to
    content text not null,

    created_at datetime default current_timestamp,

    foreign key (user_id) references users(id) on delete set null,
    foreign key (video_id) references videos(id) on delete cascade,
    foreign key (parent_id) references comments(id) on delete cascade
);

-- video likes
create table if not exists videolikes (
    id integer primary key autoincrement,
    video_id integer not null,
    user_id integer not null,
    islike integer not null default 1 check (islike in (0, 1)), -- enum ( 1 = like | 0 = dislike )

    unique(video_id, user_id), -- only one like / dislike per user per video

    foreign key (user_id) references users(id) on delete cascade,
    foreign key (video_id) references videos(id) on delete cascade
);

-- comment likes
create table if not exists commentlikes (
    id integer primary key autoincrement,
    comment_id integer not null,
    user_id integer not null,
    islike integer not null default 1 check (islike in (0, 1)), -- enum ( 1 = like | 0 = dislike )

    unique(comment_id, user_id), -- only one like / dislike per user per comment

    foreign key (user_id) references users(id) on delete cascade,
    foreign key (comment_id) references comments(id) on delete cascade
);