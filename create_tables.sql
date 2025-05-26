/* =========================
   TYPES ENUM / DOMAINES
   ========================= */
CREATE TYPE like_value              AS ENUM ('like', 'nope');
CREATE TYPE participation_state     AS ENUM ('interested', 'going');
CREATE TYPE target_kind             AS ENUM ('user', 'event', 'place');

CREATE TYPE gender_value            AS ENUM ('man', 'woman');
CREATE TYPE orientation_value       AS ENUM ('heterosexual', 'other');
CREATE TYPE provider_value AS ENUM ('facebook', 'instagram', 'X', 'linkedin', 'ticketmaster', 'snapchat', 'tiktok'); /*on aurait pu faire juste du TEXT mais le projet nous dit au moins deux réseau*/




/* =========================
   TABLES DE RÉFÉRENCE
   ========================= */
CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    name        TEXT    NOT NULL,
    parent_id   INTEGER REFERENCES category(category_id)
);

CREATE TABLE tag (
    tag_id SERIAL PRIMARY KEY,
    type   TEXT NOT NULL
);

CREATE TABLE tag_category (          -- M-N Tag <> Category
    tag_id      INTEGER REFERENCES tag(tag_id)        ON DELETE CASCADE,
    category_id INTEGER REFERENCES category(category_id) ON DELETE CASCADE,
    PRIMARY KEY (tag_id, category_id)
);

/* =========================
   UTILISATEURS & COMPTES
   ========================= */
CREATE TABLE "user" (
    user_id     SERIAL PRIMARY KEY,
    pseudo      TEXT NOT NULL UNIQUE,
    email       TEXT NOT NULL UNIQUE,
    height_cm   SMALLINT CHECK (height_cm BETWEEN 50 AND 300),
    weight_kg   NUMERIC(5,2) CHECK (weight_kg > 0),
    eye_color   TEXT,
    city        TEXT,
    country     TEXT, 
    gender      gender_value,     
    orientation orientation_value,
    birthday    DATE,
    CHECK (birthday <= CURRENT_DATE - INTERVAL '18 years') -- Vérifie que l'utilisateur est majeur
);

CREATE TABLE subscription (
    sub_id     SERIAL PRIMARY KEY,
    user_id    INTEGER REFERENCES "user"(user_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date   DATE
);

CREATE TABLE social_account (
    sa_id                           SERIAL PRIMARY KEY,
    user_id                         INTEGER REFERENCES "user"(user_id) ON DELETE CASCADE,
    provider    provider_value      NOT NULL,
    external_uid                    TEXT   NOT NULL,
    UNIQUE (provider, external_uid)
);

CREATE TABLE digital_trace (
    trace_id   SERIAL PRIMARY KEY,
    sa_id      INTEGER REFERENCES social_account(sa_id) ON DELETE CASCADE,
    trace_type TEXT      NOT NULL,
    ts         TIMESTAMP NOT NULL,
    payload    JSONB
);

/* =========================
   LIEUX & ÉVÉNEMENTS
   ========================= */
CREATE TABLE place (
    place_id SERIAL PRIMARY KEY,
    name     TEXT NOT NULL,
    address  TEXT,
    city     TEXT,
    country  TEXT
);

CREATE TABLE event (
    event_id     SERIAL PRIMARY KEY,
    title        TEXT NOT NULL,
    description  TEXT,
    -- tag_id facultatif ; les tags « secondaires » passent par TagAssignment
    tag_id       INTEGER REFERENCES tag(tag_id),
    starts_at    TIMESTAMP NOT NULL,
    ends_at      TIMESTAMP,
    price        NUMERIC(8,2) CHECK (price >= 0),
    place_id     INTEGER REFERENCES place(place_id),
    organiser_id INTEGER REFERENCES "user"(user_id),
    source       TEXT
);

/* =========================
   ASSOCIATIONS AVEC ATTRIBUTS
   ========================= */
CREATE TABLE likes (
    source_user_id INTEGER REFERENCES "user"(user_id) ON DELETE CASCADE,
    target_user_id INTEGER REFERENCES "user"(user_id) ON DELETE CASCADE,
    value          like_value       NOT NULL,
    created_at     TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    canceled_at    TIMESTAMP,
    PRIMARY KEY (source_user_id, target_user_id)
);

CREATE TABLE participation (
    user_id    INTEGER REFERENCES "user"(user_id)  ON DELETE CASCADE,
    event_id   INTEGER REFERENCES event(event_id)  ON DELETE CASCADE,
    status     participation_state NOT NULL,
    created_at TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, event_id)
);

/* Remplacement de la table polymorphe tag_assignment par 3 tables spécifiques */
CREATE TABLE tag_user_assignment (
    tag_id   INTEGER REFERENCES tag(tag_id) ON DELETE CASCADE,
    user_id  INTEGER REFERENCES "user"(user_id) ON DELETE CASCADE,
    PRIMARY KEY (tag_id, user_id)
);

CREATE TABLE tag_event_assignment (
    tag_id   INTEGER REFERENCES tag(tag_id) ON DELETE CASCADE,
    event_id INTEGER REFERENCES event(event_id) ON DELETE CASCADE,
    PRIMARY KEY (tag_id, event_id)
);

CREATE TABLE tag_place_assignment (
    tag_id   INTEGER REFERENCES tag(tag_id) ON DELETE CASCADE,
    place_id INTEGER REFERENCES place(place_id) ON DELETE CASCADE,
    PRIMARY KEY (tag_id, place_id)
);

/* =========================
   NOTIFICATIONS
   ========================= */
CREATE TABLE notification (
    notification_id SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES "user"(user_id) ON DELETE CASCADE,
    message     TEXT      NOT NULL,
    sent_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* =========================
   CONTRAINTES SUPPLÉMENTAIRES
   ========================= */

/* Empêcher un like sur soi-même */
ALTER TABLE likes
    ADD CONSTRAINT no_self_like
    CHECK (source_user_id <> target_user_id);


/* Un évènement ne peut pas finir avant de commencer */
ALTER TABLE event
    ADD CONSTRAINT ends_after_starts
    CHECK (ends_at IS NULL OR ends_at >= starts_at);



/* ================================================================
   3. TRIGGER : interdiction d’annuler un like sans abonnement actif
   ================================================================ */
CREATE OR REPLACE FUNCTION trg_check_subscription_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Détecter la tentative d’ajout / modification de canceled_at
    IF NEW.canceled_at IS NOT NULL
       AND (OLD.canceled_at IS NULL OR NEW.canceled_at <> OLD.canceled_at)
    THEN
        -- abonnement actif = intervalle [start_date ; end_date] couvrant NOW()
        IF NOT EXISTS (
            SELECT 1
            FROM subscription
            WHERE user_id     = NEW.source_user_id
              AND start_date <= CURRENT_DATE
              AND (end_date IS NULL OR end_date >= CURRENT_DATE)
        ) THEN
            RAISE EXCEPTION
              'Annulation impossible : aucun abonnement actif pour l’utilisateur %',
              NEW.source_user_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Déclencheur
CREATE TRIGGER tg_like_cancel_requires_subscription
BEFORE UPDATE OF canceled_at ON likes
FOR EACH ROW
EXECUTE FUNCTION trg_check_subscription_active();




/* ================================================================
4. MATERIALIZED VIEW matches Effective = user 1 likes user 2 and reciprocally
================================================================ */
CREATE MATERIALIZED VIEW mv_matches AS
SELECT
    LEAST(l1.source_user_id, l1.target_user_id)  AS user_a,
    GREATEST(l1.source_user_id, l1.target_user_id) AS user_b,
    l1.created_at AS like_time_a,
    l2.created_at AS like_time_b
FROM likes l1
JOIN likes l2
      ON l1.source_user_id = l2.target_user_id
     AND l1.target_user_id = l2.source_user_id
WHERE l1.value = 'like'
  AND l2.value = 'like'
  AND l1.canceled_at IS NULL
  AND l2.canceled_at IS NULL
  -- éviter le doublon (A,B) / (B,A)
  AND l1.source_user_id < l1.target_user_id;


  /* à rafraîchir avec REFRESH MATERIALIZED VIEW matched_users;*/