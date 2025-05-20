-- 1. Utilisateurs ayant au moins 3 participations
SELECT u.user_id, u.pseudo, COUNT(*) AS nb_events
FROM "user" u
JOIN participation p ON u.user_id = p.user_id
GROUP BY u.user_id
HAVING COUNT(*) >= 3;

-- 2. Moyenne du poids par genre
SELECT gender, AVG(weight_kg) AS avg_weight
FROM "user"
GROUP BY gender;

-- 3. Nombre moyen de tags par event
SELECT AVG(tag_count) FROM (
  SELECT COUNT(*) AS tag_count
  FROM tag_event_assignment
  GROUP BY event_id
) AS sub;

-- 4. Jointure réflexive : utilisateurs qui se sont likés (matchs)
SELECT l1.source_user_id AS user1, l1.target_user_id AS user2
FROM likes l1
JOIN likes l2 ON l1.source_user_id = l2.target_user_id AND l1.target_user_id = l2.source_user_id
WHERE l1.value = 'like' AND l2.value = 'like';

-- 5. Sous-requête corrélée : utilisateurs ayant liké plus que la moyenne
SELECT u.user_id, u.pseudo
FROM "user" u
WHERE (
  SELECT COUNT(*) FROM likes l WHERE l.source_user_id = u.user_id
) > (
  SELECT AVG(likes_count)::int FROM (
    SELECT COUNT(*) AS likes_count FROM likes GROUP BY source_user_id
  ) AS sub
);

-- 6. Sous-requête dans le FROM : moyenne de tags utilisateurs par genre
SELECT u.gender, AVG(tag_ct) AS avg_tags
FROM (
  SELECT user_id, COUNT(*) AS tag_ct
  FROM tag_user_assignment
  GROUP BY user_id
) AS tag_counts
JOIN "user" u ON tag_counts.user_id = u.user_id
GROUP BY u.gender;

-- 7. LEFT JOIN pour utilisateurs sans participation
SELECT u.user_id, u.pseudo, p.event_id
FROM "user" u
LEFT JOIN participation p ON u.user_id = p.user_id
WHERE p.event_id IS NULL;

-- 8. Informations d’événement les plus chers par ville
SELECT city, MAX(price) AS max_price
FROM event
JOIN place USING(place_id)
GROUP BY city;

-- 9. Utilisateurs ayant liké tout le monde (correlated)
SELECT u1.user_id
FROM "user" u1
WHERE NOT EXISTS (
  SELECT 1 FROM "user" u2
  WHERE u1.user_id <> u2.user_id
    AND NOT EXISTS (
      SELECT 1 FROM likes l
      WHERE l.source_user_id = u1.user_id AND l.target_user_id = u2.user_id
    )
);

-- 10. Même requête avec agrégation
SELECT source_user_id
FROM likes
GROUP BY source_user_id
HAVING COUNT(DISTINCT target_user_id) = (SELECT COUNT(*) - 1 FROM "user");

-- 11. Requête fenêtrage : top 3 plus nopés par mois
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

-- 12. Requête récursive : hiérarchie des catégories
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

-- 13. Deux requêtes qui diffèrent avec NULL
-- a) WHERE IS NULL
SELECT * FROM event WHERE ends_at IS NULL;
-- b) WHERE ends_at <> ends_at -- sera toujours FALSE sauf NULL
SELECT * FROM event WHERE NOT (ends_at = ends_at);

-- 14. Utilisateurs avec au moins un tag en commun
SELECT DISTINCT u1.user_id, u2.user_id
FROM tag_user_assignment t1
JOIN tag_user_assignment t2 ON t1.tag_id = t2.tag_id AND t1.user_id < t2.user_id
JOIN "user" u1 ON u1.user_id = t1.user_id
JOIN "user" u2 ON u2.user_id = t2.user_id;

-- 15. Utilisateurs avec le plus de likes envoyés
SELECT u.user_id, u.pseudo, COUNT(*) AS total_likes
FROM "user" u
JOIN likes l ON l.source_user_id = u.user_id
GROUP BY u.user_id
ORDER BY total_likes DESC
LIMIT 5;

-- 16. Liste d’événements futurs auxquels un utilisateur n’a pas participé
SELECT e.*
FROM event e
WHERE e.starts_at > NOW()
  AND NOT EXISTS (
    SELECT 1 FROM participation p
    WHERE p.user_id = 1 AND p.event_id = e.event_id
);

-- 17. Moyenne des événements par organisateur
SELECT organiser_id, COUNT(*) AS event_count
FROM event
GROUP BY organiser_id;

-- 18. Liste d’événements avec leurs tags
SELECT e.title, string_agg(t.type, ', ') AS tags
FROM event e
JOIN tag_event_assignment tea ON tea.event_id = e.event_id
JOIN tag t ON t.tag_id = tea.tag_id
GROUP BY e.title;

-- 19. Tags les plus utilisés
SELECT t.type, COUNT(*) AS usage_count
FROM tag t
LEFT JOIN tag_user_assignment tua ON t.tag_id = tua.tag_id
LEFT JOIN tag_event_assignment tea ON t.tag_id = tea.tag_id
GROUP BY t.type
ORDER BY usage_count DESC;

-- 20. Pseudo + nb de matchs effectifs
SELECT u.pseudo, COUNT(*) AS nb_matches
FROM mv_matches m
JOIN "user" u ON u.user_id = m.user_a
GROUP BY u.pseudo;
