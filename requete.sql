-- Active: 1739617017649@@localhost@5432@le_big_match@public
/*a faire par mon ami d'afrique*/
SELECT source_user_id,
       COUNT(*) AS nb_annulations
FROM   likes
WHERE  canceled_at IS NOT NULL
GROUP  BY source_user_id
ORDER  BY nb_annulations DESC
LIMIT 10;


SELECT * from user ;