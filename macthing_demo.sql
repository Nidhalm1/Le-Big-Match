-- Active: 1739617017649@@localhost@5432@le_big_match@public
-- ========================================
--  DEMO INTERACTIVE : MATCHING + RECOMMANDATIONS
-- ========================================
-- A exécuter dans psql : \i matching_demo.sql

-- Étape 1 : saisir un utilisateur
\prompt 'Entrez l\'ID de l\'utilisateur pour le matching : ' v_user_id

-- ========================================
--   Utilisateurs les plus compatibles
-- Score = (tags en commun * 2) + (événements partagés)
-- ========================================
SELECT
    user_b,
    (common_tags * 2 + common_events) AS affinity_score
FROM mv_affinity
WHERE user_a = :'v_user_id'
ORDER BY affinity_score DESC
LIMIT 5;

-- ========================================
--   Recommandation d’événements
-- Parmi ceux auxquels des profils compatibles participent
-- ========================================
SELECT
    e.event_id,
    e.title,
    COUNT(*) AS compatible_attendees,
    ROUND(AVG(a.common_tags * 2 + a.common_events), 2) AS avg_affinity_score
FROM event e
JOIN participation p ON p.event_id = e.event_id
JOIN mv_affinity a ON a.user_b = p.user_id AND a.user_a = :'v_user_id'
WHERE e.starts_at > NOW()
GROUP BY e.event_id, e.title
ORDER BY avg_affinity_score DESC, compatible_attendees DESC
LIMIT 5;
