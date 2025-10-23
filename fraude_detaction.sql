--- CAs d'usage : Detection de fraude


sqlplus ryan/ryan23@localhost:1521/FREEPDB1

--- creation des  Table pour stocker les vecteurs de texte
--- structure de ma table fraud_text_vectors
CREATE TABLE fraud_text_vectors (
    id NUMBER PRIMARY KEY,
    phrase VARCHAR2(1000),
    vector VECTOR(384)
);

--- cree une sequence pour les id
CREATE SEQUENCE nlp_seq START WITH 1 INCREMENT BY 1;


--- reinitialiser la sequence si on vide la table 
DROP SEQUENCE nlp_seq;
CREATE SEQUENCE nlp_seq START WITH 1 INCREMENT BY 1;


--- ex de phrase
Cher client, nous avons détecté un accès non autorisé à votre compte.



--- Création d’un index vectoriel pour accélérer les recherches
-- L’index IVF_COSINE est adapté pour les mesures de similarité cosinus, ce qui est généralement pertinent pour des embeddings de texte
--- en mode 
sqlplus / as sysdba
-- increase in memory SIZE
ALTER SYSTEM SET INMEMORY_SIZE = 1G SCOPE=SPFILE;
SHUTDOWN IMMEDIATE;
STARTUP;
SHOW PARAMETER INMEMORY_SIZE;
--- result inmemory = 1G

--- puis se reconnecter a ryan et faire
ALTER TABLE fraud_text_vectors INMEMORY;

-- maintenat cree les index
CREATE VECTOR INDEX fraud_text_vector_index ON fraud_text_vectors (vector) 
ORGANIZATION INMEMORY NEIGHBOR GRAPH
DISTANCE COSINE
WITH TARGET ACCURACY 95;


select * from fraud_text_vectors;

--- Requête SQL pour détecter une anomalie
SELECT phrase ,id
FROM fraud_text_vectors
ORDER BY VECTOR_DISTANCE( vecteur, :query_vector, EUCLIDEAN )
FETCH EXACT FIRST 10 ROWS ONLY;

SELECT phrase ,id
FROM fraud_text_vectors
ORDER BY VECTOR_DISTANCE( vecteur, :query_vector, COSINE )
FETCH EXACT FIRST 10 ROWS ONLY;





CREATE TABLE custom_dist_tab( id NUMBER, data_vector VECTOR(2, FLOAT32));

INSERT INTO custom_dist_tab VALUES (1, vector('[1.1,2.2]', 2, float32));
INSERT INTO custom_dist_tab VALUES (2, vector('[2.2,3.3]', 2, float32));
INSERT INTO custom_dist_tab VALUES (3, vector('[3.3,4.4]', 2, float32));
INSERT INTO custom_dist_tab VALUES (4, vector('[4.4,5.5]', 2, float32));
INSERT INTO custom_dist_tab VALUES (5, vector('[5.5,6.6]', 2, float32));

CREATE OR REPLACE FUNCTION euclidean_sq_vector_distance("a" VECTOR, "b"
VECTOR)
RETURN BINARY_DOUBLE
DETERMINISTIC PARALLEL_ENABLE
AS MLE LANGUAGE JAVASCRIPT PURE
{{
let len = a.length;
let sum = 0;
for(let i = 0; i < len; i++) {
const tmp = a[i] - b[i];
sum += tmp * tmp;
}
return sum;
}};
/


CREATE VECTOR INDEX cust_dist_idx_hnsw ON custom_dist_tab (data_vector)
ORGANIZATION INMEMORY
NEIGHBOR GRAPH WITH TARGET ACCURACY 95
DISTANCE CUSTOM EUCLIDEAN_SQ_VECTOR_DISTANCE
PARALLEL 3;

Select
data_vector,
euclidean_sq_vector_distance(data_vector, VECTOR('[1, 2]')) edist
FROM custom_dist_tab
ORDER BY edist
FETCH FIRST 5 ROWS ONLY;












