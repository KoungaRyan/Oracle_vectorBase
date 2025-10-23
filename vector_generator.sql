--- Using a FLOAT32 Vector Generator

--- Depuis ta session actuelle (CDB$ROOT), exécute :
ALTER SESSION SET CONTAINER = FREEPDB1;

--- Puis verifier
SELECT sys_context('USERENV','CON_NAME') FROM dual;

--- Create user RYAN in FREEPDB1
CREATE USER ryan IDENTIFIED BY ryan23;
GRANT CONNECT, RESOURCE TO ryan;
ALTER USER ryan QUOTA UNLIMITED ON USERS;

--- Veriier les utilisateur existant
SELECT username FROM dba_users where username like 'RY%';

-- Étape 3 : (hors SQL) se reconnecter à ryan@FREEPDB1
sqlplus ryan/ryan23@localhost:1521/FREEPDB1

--- Suppression de la table si elle existe
DROP TABLE genvec PURGE;

-- Création de la table pour stocker les vecteurs générés
CREATE TABLE genvec (
    id       NUMBER,         -- ID du vecteur généré
    v        VECTOR,         -- Vecteur généré
    name     VARCHAR2(500),  -- Nom du vecteur : C1 à Cn pour les centroïdes, Cx_y pour vecteur y du cluster x
    nv       VECTOR,         -- Vecteur normalisé
    ly       NUMBER          -- Nombre aléatoire pour filtrage ou autre usage
) TABLESPACE USERS;

-- Création du package (spécification)
CREATE OR REPLACE PACKAGE vector_gen_pkg AS

    TYPE t_vectors IS TABLE OF VECTOR INDEX BY PLS_INTEGER;

    FUNCTION get_coordinate(
        input_string CLOB,
        i PLS_INTEGER
    ) RETURN NUMBER;

    PROCEDURE generate_vectors(
        num_vectors     IN PLS_INTEGER,
        dimensions      IN PLS_INTEGER,
        num_clusters    IN PLS_INTEGER,
        cluster_spread  IN NUMBER,
        min_value       IN NUMBER,
        max_value       IN NUMBER
    );

END vector_gen_pkg;
/

-- Corps du package
CREATE OR REPLACE PACKAGE BODY vector_gen_pkg AS

  FUNCTION get_coordinate(input_string CLOB, i PLS_INTEGER) RETURN NUMBER IS
    start_pos      NUMBER;
    end_pos        NUMBER;
    coord          VARCHAR2(100);
    comma_count    NUMBER := 0;
    commas         NUMBER;
    working_string CLOB;
  BEGIN
    working_string := TRIM(BOTH '[]' FROM input_string);
    commas := LENGTH(working_string) - LENGTH(REPLACE(working_string, ',', ''));
    start_pos := 1;
    end_pos := INSTR(working_string, ',', start_pos);
    IF i <= 0 OR i > commas + 1 THEN RETURN NULL; END IF;

    LOOP
      IF comma_count + 1 = i THEN
        coord := CASE
          WHEN end_pos = 0 THEN SUBSTR(working_string, start_pos)
          ELSE SUBSTR(working_string, start_pos, end_pos - start_pos)
        END;
        coord := REPLACE(TRIM(coord), ',', '.');

        IF coord LIKE '%E+%' OR coord LIKE '%E-%' THEN
          DBMS_OUTPUT.PUT_LINE('SKIP sci notation: ' || coord);
          RETURN NULL;
        END IF;

        BEGIN
          RETURN TO_NUMBER(coord);
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Bad coord [' || i || ']: ' || coord);
          RETURN NULL;
        END;
      END IF;

      comma_count := comma_count + 1;
      start_pos := end_pos + 1;
      end_pos := INSTR(working_string, ',', start_pos);
      EXIT WHEN start_pos > LENGTH(working_string);
    END LOOP;

    RETURN NULL;
  END get_coordinate;

  PROCEDURE generate_random_vector(
    dimensions IN PLS_INTEGER,
    min_value  IN NUMBER,
    max_value  IN NUMBER,
    vec        OUT vector
  ) IS
    e VARCHAR2(4000);
    val NUMBER;
  BEGIN
    e := '[';
    FOR i IN 1 .. dimensions LOOP
      val := DBMS_RANDOM.VALUE(min_value, max_value);
      e := e || TO_CHAR(val, '999999990.99999999',
                         'NLS_NUMERIC_CHARACTERS = ''. ''');
      IF i < dimensions THEN e := e || ','; END IF;
    END LOOP;
    vec := VECTOR(e || ']');
  END generate_random_vector;

  PROCEDURE generate_clustered_vector(
    centroid       IN vector,
    cluster_spread IN NUMBER,
    vec            OUT vector
  ) IS
    e VARCHAR2(4000);
    d NUMBER;
    val NUMBER;
  BEGIN
    d := VECTOR_DIMENSION_COUNT(centroid);
    e := '[';
    FOR i IN 1 .. d LOOP
      val := get_coordinate(TO_CLOB(centroid), i)
             + DBMS_RANDOM.NORMAL * cluster_spread;
      e := e || TO_CHAR(val, '999999990.99999999',
                         'NLS_NUMERIC_CHARACTERS = ''. ''');
      IF i < d THEN e := e || ','; END IF;
    END LOOP;
    vec := VECTOR(e || ']');
  END generate_clustered_vector;

  FUNCTION normalize_vector(vec IN vector) RETURN vector IS
    e VARCHAR2(4000);
    d NUMBER;
    n NUMBER;
  BEGIN
    n := VECTOR_NORM(vec);
    IF n = 0 THEN RETURN vec; END IF;
    d := VECTOR_DIMENSION_COUNT(vec);
    e := '[';
    FOR i IN 1 .. d LOOP
      e := e || TO_CHAR(get_coordinate(TO_CLOB(vec), i) / n,
                        '999999990.99999999',
                        'NLS_NUMERIC_CHARACTERS = ''. ''')
              || CASE WHEN i < d THEN ',' ELSE '' END;
    END LOOP;
    RETURN VECTOR(e || ']');
  END normalize_vector;

  PROCEDURE generate_vectors(
    num_vectors    IN PLS_INTEGER,
    dimensions     IN PLS_INTEGER,
    num_clusters   IN PLS_INTEGER,
    cluster_spread IN NUMBER,
    min_value      IN NUMBER,
    max_value      IN NUMBER
  ) IS
    centroids           t_vectors;
    vectors_per_cluster PLS_INTEGER;
    remaining_vectors   PLS_INTEGER;
    vec                 vector;
    working_vector      vector;
    idx                 PLS_INTEGER := 1;
    max_id              NUMBER;
  BEGIN
    IF num_vectors <= 0 OR num_clusters < 1 OR num_vectors < num_clusters
       OR dimensions <= 0 OR dimensions > 500
       OR cluster_spread <= 0 OR min_value >= max_value THEN RETURN; END IF;

    SELECT NVL(MAX(id), 0) INTO max_id FROM genvec;

    FOR i IN 1 .. num_clusters LOOP
      generate_random_vector(dimensions, min_value, max_value,
                             centroids(i));
      working_vector := normalize_vector(centroids(i));
      INSERT INTO genvec VALUES (
        max_id + idx, centroids(i), 'C'||i, working_vector,
        DBMS_RANDOM.VALUE(3,600000000)
      );
      idx := idx + 1;
    END LOOP;

    vectors_per_cluster := TRUNC(num_vectors / num_clusters);
    remaining_vectors := MOD(num_vectors, num_clusters);

    IF vectors_per_cluster > 1 THEN
      FOR i IN 1 .. num_clusters LOOP
        FOR j IN 1 .. vectors_per_cluster - 1 LOOP
          generate_clustered_vector(centroids(i), cluster_spread, vec);
          working_vector := normalize_vector(vec);
          INSERT INTO genvec VALUES (
            max_id + idx, vec, 'C'||i||'-'||j,
            working_vector, DBMS_RANDOM.VALUE(3,600000000)
          );
          idx := idx + 1;
        END LOOP;
      END LOOP;
    END IF;

    FOR j IN 1 .. remaining_vectors LOOP
      generate_clustered_vector(centroids(1), cluster_spread, vec);
      working_vector := normalize_vector(vec);
      INSERT INTO genvec VALUES (
        max_id + idx, vec, 'C1-'||idx,
        working_vector, DBMS_RANDOM.VALUE(3,600000000)
      );
      idx := idx + 1;
    END LOOP;

    COMMIT;
  END generate_vectors;

END vector_gen_pkg;
/



---Activez l’affichage
SET SERVEROUTPUT ON;


--- Run the generate_vectors procedure of the vector_gen_pkg package with sample values:

BEGIN
  vector_gen_pkg.generate_vectors(
    num_vectors     => 100,   -- 100 vecteurs au total
    dimensions      => 3,     -- chaque vecteur a 3 composantes
    num_clusters    => 6,     -- répartis en 6 clusters
    cluster_spread  => 1,     -- écart-type = 1
    min_value       => 0,
    max_value       => 100    -- valeurs entre 0 et 100
  );
END;
/

--- Run a SELECT statement to view the newly generated vectors.
SELECT name, v FROM genvec;

---- Run a similarity search on the generated vectors in the genvec table.
DEFINE cluster_number = '&clusterid'

---- Run the following query to perform a similarity search on the generated vectors:
SELECT name
FROM genvec
ORDER BY VECTOR_DISTANCE(v,(SELECT v FROM genvec WHERE
name='C'||'&cluster_number'),EUCLIDEAN)
FETCH EXACT FIRST 20 ROWS ONLY;

---   Running a similarity search on the generated vectors, this time using the Cosine distance metric.
SELECT name
FROM genvec
ORDER BY VECTOR_DISTANCE(v,(SELECT v FROM genvec WHERE
name='C'||'&cluster_number'),COSINE)
FETCH EXACT FIRST 20 ROWS ONLY;

---Create a variable called query_vector and then use SELECT INTO to store a vector value in the variable.
VARIABLE query_vector CLOB

BEGIN
SELECT v INTO :query_vector
FROM genvec
WHERE name='C'||'&cluster_number';
END;
/

PRINT query_vector;

--- Create an explain plan for a similarity search using the query vector created in the previous step.
EXPLAIN PLAN FOR 
SELECT name
FROM genvec
ORDER BY VECTOR_DISTANCE(v, :query_vector, EUCLIDEAN)
FETCH EXACT FIRST 20 ROWS ONLY;

SELECT plan_table_output
FROM table(dbms_xplan.display('plan_table',null,'all'));

--- Create an Hierarchical Navigable Small World (HNSW) index.
CREATE VECTOR INDEX genvec_hnsw_idx ON genvec(v)
ORGANIZATION INMEMORY NEIGHBOR GRAPH
DISTANCE EUCLIDEAN
WITH TARGET ACCURACY 95;

SELECT INDEX_NAME, INDEX_TYPE, INDEX_SUBTYPE FROM USER_INDEXES;

























