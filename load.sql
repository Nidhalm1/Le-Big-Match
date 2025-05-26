-- Importe tous les CSV générés par make_csv.py via tables temporaires
-- Exécution :  psql -d le_big_match -f load.sql
\echo '==> Import Le Big Match'

BEGIN;

-- Nettoyage complet pour éviter les problèmes de séquence après un précédent ROLLBACK
TRUNCATE TABLE 
    tag_category,
    tag_user_assignment,
    tag_event_assignment,
    tag_place_assignment,
    tag,
    category,
    place,
    event,
    subscription,
    social_account,
    digital_trace,
    likes,
    participation,
    notification,
    "user"
RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS 
    tmp_user, 
    tmp_place, 
    tmp_category, 
    tmp_event, 
    tmp_sub, 
    tmp_sa, 
    tmp_dt, 
    tmp_like, 
    tmp_part, 
    tmp_tag_event, 
    tmp_tag_place, 
    tmp_tag_user, 
    tmp_notif;

/* 1. UTILISATEURS */
CREATE TEMP TABLE tmp_user (LIKE "user" INCLUDING ALL);
ALTER TABLE tmp_user DROP COLUMN user_id;
\copy tmp_user(pseudo,email,height_cm,weight_kg,eye_color,city,country,gender,orientation,birthday) FROM 'CSV/user.csv' CSV HEADER
INSERT INTO "user"(pseudo,email,height_cm,weight_kg,eye_color,city,country,gender,orientation,birthday)
SELECT * FROM tmp_user;

/* 2. PLACES */
CREATE TEMP TABLE tmp_place (LIKE place INCLUDING ALL);
ALTER TABLE tmp_place DROP COLUMN place_id;
\copy tmp_place(name,address,city,country) FROM 'CSV/place.csv' CSV HEADER
INSERT INTO place(name,address,city,country) SELECT * FROM tmp_place;

/* 3. TAGS */
\copy tag(type) FROM 'CSV/tag.csv' CSV HEADER

/* 4. CATEGORIES (racines d'abord, enfants ensuite) */
CREATE TEMP TABLE tmp_category (LIKE category INCLUDING ALL);
ALTER TABLE tmp_category DROP COLUMN category_id;
\copy tmp_category(name,parent_id) FROM 'CSV/category.csv' CSV HEADER
INSERT INTO category(name,parent_id)
SELECT name,parent_id FROM tmp_category ORDER BY parent_id IS NOT NULL, parent_id;

/* 4b. TAG_CATEGORY */
\copy tag_category(tag_id,category_id) FROM 'CSV/tag_category.csv' CSV HEADER

/* 5. EVENTS */
CREATE TEMP TABLE tmp_event (LIKE event INCLUDING ALL);
ALTER TABLE tmp_event DROP COLUMN event_id;
\copy tmp_event(title,description,tag_id,starts_at,ends_at,price,place_id,organiser_id,source) FROM 'CSV/event.csv' CSV HEADER
INSERT INTO event(title,description,tag_id,starts_at,ends_at,price,place_id,organiser_id,source)
SELECT title,description,tag_id,starts_at,ends_at,price,place_id,organiser_id,source FROM tmp_event;

/* 6. SUBSCRIPTIONS */
CREATE TEMP TABLE tmp_sub (LIKE subscription INCLUDING ALL);
ALTER TABLE tmp_sub DROP COLUMN sub_id;
\copy tmp_sub(user_id,start_date,end_date) FROM 'CSV/subscription.csv' CSV HEADER
INSERT INTO subscription(user_id,start_date,end_date) SELECT * FROM tmp_sub;

/* 7. SOCIAL ACCOUNT */
CREATE TEMP TABLE tmp_sa (LIKE social_account INCLUDING ALL);
ALTER TABLE tmp_sa DROP COLUMN sa_id;
\copy tmp_sa(user_id,provider,external_uid) FROM 'CSV/social_account.csv' CSV HEADER
INSERT INTO social_account(user_id,provider,external_uid) SELECT * FROM tmp_sa;

/* 8. DIGITAL TRACE */
CREATE TEMP TABLE tmp_dt (LIKE digital_trace INCLUDING ALL);
ALTER TABLE tmp_dt DROP COLUMN trace_id;
\copy tmp_dt(sa_id,trace_type,ts,payload) FROM 'CSV/digital_trace.csv' CSV HEADER
INSERT INTO digital_trace(sa_id,trace_type,ts,payload) SELECT * FROM tmp_dt;

/* 9. LIKES */
CREATE TEMP TABLE tmp_like (LIKE likes INCLUDING ALL);
ALTER TABLE tmp_like DROP CONSTRAINT IF EXISTS tmp_like_pkey;
\copy tmp_like(source_user_id,target_user_id,value,created_at,canceled_at) FROM 'CSV/likes.csv' CSV HEADER
INSERT INTO likes
SELECT DISTINCT ON (source_user_id, target_user_id)
    source_user_id, target_user_id, value, created_at, canceled_at
FROM tmp_like
ORDER BY source_user_id, target_user_id, created_at;

/* 10. PARTICIPATION */
CREATE TEMP TABLE tmp_part (LIKE participation INCLUDING ALL);
ALTER TABLE tmp_part DROP CONSTRAINT IF EXISTS tmp_part_pkey;
\copy tmp_part(user_id,event_id,status,created_at) FROM 'CSV/participation.csv' CSV HEADER
INSERT INTO participation
SELECT DISTINCT ON (user_id, event_id)
    user_id, event_id, status, created_at
FROM tmp_part
ORDER BY user_id, event_id, created_at;

/* 11a. TAG_EVENT_ASSIGNMENT */
CREATE TEMP TABLE tmp_tag_event (LIKE tag_event_assignment INCLUDING ALL);
\copy tmp_tag_event(tag_id,event_id) FROM 'CSV/tag_event_assignment.csv' CSV HEADER
INSERT INTO tag_event_assignment SELECT * FROM tmp_tag_event;

/* 11b. TAG_PLACE_ASSIGNMENT */
CREATE TEMP TABLE tmp_tag_place (LIKE tag_place_assignment INCLUDING ALL);
\copy tmp_tag_place(tag_id,place_id) FROM 'CSV/tag_place_assignment.csv' CSV HEADER
INSERT INTO tag_place_assignment SELECT * FROM tmp_tag_place;

/* 11c. TAG_USER_ASSIGNMENT */
CREATE TEMP TABLE tmp_tag_user (LIKE tag_user_assignment INCLUDING ALL);
\copy tmp_tag_user(tag_id,user_id) FROM 'CSV/tag_user_assignment.csv' CSV HEADER
INSERT INTO tag_user_assignment SELECT * FROM tmp_tag_user;

/* 12. NOTIFICATION */
CREATE TEMP TABLE tmp_notif (LIKE notification INCLUDING ALL);
ALTER TABLE tmp_notif DROP COLUMN notification_id;
\copy tmp_notif(user_id,message,sent_at) FROM 'CSV/notification.csv' CSV HEADER
INSERT INTO notification(user_id,message,sent_at) SELECT * FROM tmp_notif;

COMMIT;

VACUUM ANALYZE;
\echo '✅ Import terminé sans violation de contraintes'
