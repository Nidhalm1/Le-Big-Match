-- ========================================
-- 🎤 Le Big Match : Présentation interactive
-- ========================================
-- A lancer dans psql : \i presentation_demo.sql

-- ========================================
-- 1. Requête paramétrable : événements à venir dans une ville
\prompt 'Tapez le nom d\'une ville : ' v_city

SELECT e.title, e.starts_at, p.name AS lieu
FROM event e
JOIN place p ON e.place_id = p.place_id
WHERE p.city = :v_city AND e.starts_at > NOW();

-- ========================================
-- 2. Requête paramétrable : utilisateurs compatibles avec un utilisateur donné
\prompt 'Tapez l\'ID de l\'utilisateur : ' v_user_id

SELECT
    user_b,
    (common_tags * 2 + common_events) AS affinity_score
FROM mv_affinity
WHERE user_a = :'v_user_id'
ORDER BY affinity_score DESC
LIMIT 5;

-- ========================================
-- 3. Recommandation d'événements compatibles
SELECT
    e.event_id,
    e.title,
    COUNT(*) AS compatible_attendees,
    AVG(a.common_tags * 2 + a.common_events) AS avg_affinity_score
FROM event e
JOIN participation p ON p.event_id = e.event_id
JOIN mv_affinity a ON a.user_b = p.user_id AND a.user_a = :'v_user_id'
WHERE e.starts_at > NOW()
GROUP BY e.event_id, e.title
ORDER BY avg_affinity_score DESC, compatible_attendees DESC
LIMIT 5;

-- ========================================
-- 4. Classement des utilisateurs les plus likés (LIKE reçus)
SELECT pseudo, COUNT(*) AS total_likes
FROM likes l
JOIN "user" u ON u.user_id = l.target_user_id
WHERE l.value = 'like'
GROUP BY pseudo
ORDER BY total_likes DESC
LIMIT 10;

-- ========================================
-- 5. Utilisateurs ayant liké plus que la moyenne (sous-requête corrélée)
SELECT u.user_id, u.pseudo
FROM "user" u
WHERE (
  SELECT COUNT(*) FROM likes l WHERE l.source_user_id = u.user_id
) > (
  SELECT AVG(likes_count)::int FROM (
    SELECT COUNT(*) AS likes_count FROM likes GROUP BY source_user_id
  ) AS sub
);

-- ========================================
-- 6. Top 3 utilisateurs les plus nopés par mois (fenêtrage)
SELECT pseudo, month, total_nopes
FROM (
  SELECT u.pseudo,
         EXTRACT(MONTH FROM l.created_at) AS month,
         COUNT(*) AS total_nopes,
         RANK() OVER (PARTITION BY EXTRACT(MONTH FROM l.created_at) ORDER BY COUNT(*) DESC) AS rk
  FROM likes l
  JOIN "user" u ON u.user_id = l.target_user_id
  WHERE l.value = 'nope'
  GROUP BY u.pseudo, month
) AS sub
WHERE rk <= 3;

-- ========================================
-- 7. Liste des événements avec leurs tags associés
SELECT e.title, string_agg(t.type, ', ') AS tags
FROM event e
JOIN tag_event_assignment tea ON tea.event_id = e.event_id
JOIN tag t ON t.tag_id = tea.tag_id
GROUP BY e.title;

-- ========================================
-- 8. Moyenne de tags par genre (avec PREPARE + EXECUTE)
PREPARE avg_tags_by_gender AS
SELECT u.gender, AVG(tag_ct)
FROM (
  SELECT user_id, COUNT(*) AS tag_ct
  FROM tag_user_assignment
  GROUP BY user_id
) AS t
JOIN "user" u ON u.user_id = t.user_id
GROUP BY u.gender;

EXECUTE avg_tags_by_gender;

-- ========================================
-- 9. Requête récursive : affichage hiérarchique des catégories
WITH RECURSIVE cat_hierarchy AS (
  SELECT category_id, name, parent_id, 0 AS depth
  FROM category
  WHERE parent_id IS NULL
  UNION
  SELECT c.category_id, c.name, c.parent_id, h.depth + 1
  FROM category c
  JOIN cat_hierarchy h ON c.parent_id = h.category_id
)
SELECT * FROM cat_hierarchy;

-- ========================================
-- 10. Tags les plus utilisés (utilisateurs + événements)
SELECT t.type, COUNT(*) AS usage_count
FROM tag t
LEFT JOIN tag_user_assignment tua ON t.tag_id = tua.tag_id
LEFT JOIN tag_event_assignment tea ON t.tag_id = tea.tag_id
GROUP BY t.type
ORDER BY usage_count DESC
LIMIT 10;
