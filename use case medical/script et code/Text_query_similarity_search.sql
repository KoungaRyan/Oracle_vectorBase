CREATE TABLE patient_cases (
  id NUMBER PRIMARY KEY,
  description CLOB, 
  traitement_prescrit VARCHAR2(500),
  outcome VARCHAR2(100),
  vector VECTOR(768, FLOAT32)
);


select ID, Description from patient_cases FETCH FIRST 5 row only;

select * from patient_cases where ID = 2;

select id, description, traitement_prescrit, outcome from patient_cases FETCH FIRST 5 ROWS ONLY;

desc patient_cases;

CREATE TABLE new_patient (
    id NUMBER PRIMARY KEY,
    description CLOB,
    vector VECTOR(768, FLOAT32)
);
desc new_patient;

------------
-- Recherche des 5 cas les plus proches d’un vecteur donné
select count(*) from patient_cases;

SELECT
  np.description AS new_patient_description,
  p.description AS similar_patient_cases,
  ROUND(VECTOR_DISTANCE(p.vector, np.vector, COSINE), 2) AS score,
  p.traitement_prescrit as patient_case_treatment
FROM patient_cases p
CROSS JOIN new_patient np
WHERE np.id = 1
ORDER BY VECTOR_DISTANCE(p.vector, np.vector, COSINE) ASC
FETCH FIRST 10 ROWS ONLY;

SELECT p.traitement_prescrit,
       p.outcome,
       VECTOR_DISTANCE(p.vector, np.vector, EUCLIDEAN) AS euclid_score,
       VECTOR_DISTANCE(p.vector, np.vector, MANHATTAN) AS manhattan_score,
       VECTOR_DISTANCE(p.vector, np.vector, DOT) AS dot_score,
       VECTOR_DISTANCE(p.vector, np.vector, COSINE) AS Cos_score
FROM patient_cases p
CROSS JOIN new_patient np
WHERE np.id = 5
ORDER BY euclid_score ASC
FETCH FIRST 5 ROWS ONLY;

