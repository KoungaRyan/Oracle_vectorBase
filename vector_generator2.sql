--- Using a FLOAT32 Vector Generator

--- se connecter a oracle avec l'utilisateur ryan et son mots de passe
connect SYSTEM/oracle23


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
	  comma_pos      NUMBER;
	  coord          VARCHAR2(100);
	  comma_count    NUMBER := 0;
	  commas         NUMBER;
	  working_string CLOB;
	BEGIN
	  working_string := TRIM(BOTH '[]' FROM input_string);
	  commas := LENGTH(working_string) - LENGTH(REPLACE(working_string, ',', ''));

	  start_pos := 1;
	  end_pos := INSTR(working_string, ',', start_pos);

	  IF i <= 0 OR i > commas + 1 THEN
		RETURN NULL;
	  END IF;

	  LOOP
		IF comma_count + 1 = i THEN
		  IF end_pos = 0 THEN
			coord := SUBSTR(working_string, start_pos);
		  ELSE
			coord := SUBSTR(working_string, start_pos, end_pos - start_pos);
		  END IF;

		  -- Nettoyer le texte (éliminer les espaces, convertir virgule -> point)
		  coord := REPLACE(TRIM(coord), ',', '.');

		  -- Tentative de conversion sécurisée
		  BEGIN
			RETURN TO_NUMBER(coord);
		  EXCEPTION
			WHEN OTHERS THEN
			  DBMS_OUTPUT.PUT_LINE('Erreur conversion coord [' || i || '] = ' || coord);
			  RETURN NULL;  -- ou RAISE;
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
    e CLOB;
  BEGIN
    e := '[';
    FOR i IN 1 .. dimensions - 1 LOOP
      e := e || TO_CHAR(DBMS_RANDOM.VALUE(min_value, max_value), 'FM999999990.99999999') || ',';
    END LOOP;
    e := e || TO_CHAR(DBMS_RANDOM.VALUE(min_value, max_value), 'FM999999990.99999999') || ']';
    vec := VECTOR(e);
  END generate_random_vector;

  PROCEDURE generate_clustered_vector(
    centroid       IN vector,
    cluster_spread IN NUMBER,
    vec            OUT vector
  ) IS
    e CLOB;
    d NUMBER;
  BEGIN
    d := VECTOR_DIMENSION_COUNT(centroid);
    e := '[';
    FOR i IN 1 .. d - 1 LOOP
      e := e || TO_CHAR(get_coordinate(TO_CLOB(centroid), i) + (DBMS_RANDOM.NORMAL * cluster_spread), 'FM999999990.99999999') || ',';
    END LOOP;
    e := e || TO_CHAR(get_coordinate(TO_CLOB(centroid), d) + (DBMS_RANDOM.NORMAL * cluster_spread), 'FM999999990.99999999') || ']';
    vec := VECTOR(e);
  END generate_clustered_vector;

  FUNCTION normalize_vector(vec IN vector) RETURN vector IS
    e CLOB;
    v CLOB;
    n NUMBER;
    d NUMBER;
  BEGIN
    n := VECTOR_NORM(vec);
    v := TO_CLOB(vec);
    d := VECTOR_DIMENSION_COUNT(vec);
    e := '[';
    FOR i IN 1 .. d - 1 LOOP
      e := e || TO_CHAR(get_coordinate(v, i) / n, 'FM999999990.99999999') || ',';
    END LOOP;
    e := e || TO_CHAR(get_coordinate(v, d) / n, 'FM999999990.99999999') || ']';
    RETURN VECTOR(e);
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
    idx                 PLS_INTEGER := 1;
    max_id              NUMBER;
    working_vector      vector;
  BEGIN
    IF (num_vectors) <= 0 OR (num_clusters) < 1 OR (num_vectors < num_clusters) OR
       (dimensions <= 0) OR (dimensions > 500) OR (cluster_spread <= 0) OR
       (min_value >= max_value) THEN
      RETURN;
    END IF;

    SELECT MAX(id) INTO max_id FROM genvec;
    IF max_id IS NULL THEN
      max_id := 0;
    END IF;

    FOR i IN 1 .. num_clusters LOOP
      generate_random_vector(dimensions, min_value, max_value, centroids(i));
      working_vector := normalize_vector(centroids(i));
      INSERT INTO genvec VALUES (
        max_id + idx,
        centroids(i),
        'C' || i,
        working_vector,
        DBMS_RANDOM.VALUE(3, 600000000)
      );
      idx := idx + 1;
    END LOOP;

    vectors_per_cluster := TRUNC(num_vectors / num_clusters);
    remaining_vectors := num_vectors MOD num_clusters;

    IF vectors_per_cluster > 1 THEN
      FOR i IN 1 .. num_clusters LOOP
        FOR j IN 1 .. (vectors_per_cluster - 1) LOOP
          generate_clustered_vector(centroids(i), cluster_spread, vec);
          working_vector := normalize_vector(vec);
          INSERT INTO genvec VALUES (
            max_id + idx,
            vec,
            'C' || i || '-' || j,
            working_vector,
            DBMS_RANDOM.VALUE(3, 600000000)
          );
          idx := idx + 1;
        END LOOP;
      END LOOP;
    END IF;

    IF remaining_vectors > 0 THEN
      FOR j IN 1 .. remaining_vectors LOOP
        generate_clustered_vector(centroids(1), cluster_spread, vec);
        working_vector := normalize_vector(vec);
        INSERT INTO genvec VALUES (
          max_id + idx,
          vec,
          'C1-' || idx,
          working_vector,
          DBMS_RANDOM.VALUE(3, 600000000)
        );
        idx := idx + 1;
      END LOOP;
    END IF;

    COMMIT;
  END generate_vectors;

END vector_gen_pkg;
/




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















