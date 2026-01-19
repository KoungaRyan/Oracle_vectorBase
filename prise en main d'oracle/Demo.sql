--- se connecter a oracle 
sqlplus SYSTEM/oracle23

--- cree un utilisateur dans oracle :
CREATE USER ryan IDENTIFIED BY ryan23;
GRANT CONNECT, RESOURCE TO ryan;
ALTER USER ryan QUOTA UNLIMITED ON USERS;

--- Veriier les utilisateur existant
SELECT username FROM dba_users where username like 'ryan%';

--- se connecter a oracle avec l'utilisateur ryan et son mots de passe
sqlplus ryan/ryan23@localhost:1521/FREEPDB1

--- 
CREATE TABLE my_vectors (
	id NUMBER, 
	embedding VECTOR
	);

--- In this example, each vector that is stored Must have 768 dimensions and  will be formatted as an INT8.
CREATE TABLE my_vectors (
	id NUMBER,
	embedding VECTOR(768, INT8)
	) ;

--- Here is some simple code that shows how to define and insert a VECTOR in a table:
DROP TABLE my_vect_tab PURGE;

CREATE TABLE my_vect_tab (
	v01 VECTOR(3, INT8)
	) TABLESPACE USERS;

---- Liste des tables disponible dans la bd
SELECT table_name FROM user_tables where table_name like 'MY_%';

INSERT INTO my_vect_tab VALUES ('[10, 20, 30]');

SELECT * FROM my_vect_tab;

--- Describe the table
DESC my_vect_tab;


---- SPARSE Vectors

CREATE TABLE my_sparse_tab (
v01 VECTOR(5, INT8, SPARSE)
)TABLESPACE USERS;

INSERT INTO my_sparse_tab VALUES('[5,[2,4],[10,20]]');
INSERT INTO my_sparse_tab VALUES('[[2,4],[10,20]]');

---- Insert dense vectors in to a SPARSE vector table
--- This command fails 
INSERT INTO my_sparse_tab VALUES('[0, 10, 0, 20, 0]');

--- this command work 
INSERT INTO my_sparse_tab VALUES (TO_VECTOR('[0,0,10,0,20]', 5, INT8, DENSE));

--- You can also transform a SPARSE vector into a DENSE textual form if needed and vice versa:
SELECT FROM_VECTOR(v01 RETURNING CLOB FORMAT DENSE)
FROM my_sparse_tab
WHERE ROWNUM<2;

--- Insert Vectors in a Database Table Using the INSERT Statement
CREATE TABLE galaxies (
	id NUMBER, 
	name VARCHAR2(50),
	doc VARCHAR2(500),
	embedding VECTOR
)TABLESPACE USERS;


INSERT INTO galaxies VALUES (1, 'M31', 'Messier 31 is a barred spiral galaxy
in the Andromeda constellation which has a lot of barred spiral galaxies.',
'[0,2,2,0,0]');
INSERT INTO galaxies VALUES (2, 'M33', 'Messier 33 is a spiral galaxy in the
Triangulum constellation.', '[0,0,1,0,0]');
INSERT INTO galaxies VALUES (3, 'M58', 'Messier 58 is an intermediate barred
spiral galaxy in the Virgo constellation.', '[1,1,1,0,0]');
INSERT INTO galaxies VALUES (4, 'M63', 'Messier 63 is a spiral galaxy in the
Canes Venatici constellation.', '[0,0,1,0,0]');
INSERT INTO galaxies VALUES (5, 'M77', 'Messier 77 is a barred spiral galaxy
in the Cetus constellation.', '[0,1,1,0,0]');
INSERT INTO galaxies VALUES (6, 'M91', 'Messier 91 is a barred spiral galaxy
in the Coma Berenices constellation.', '[0,1,1,0,0]');
INSERT INTO galaxies VALUES (7, 'M49', 'Messier 49 is a giant elliptical
galaxy in the Virgo constellation.', '[0,0,0,1,1]');
INSERT INTO galaxies VALUES (8, 'M60', 'Messier 60 is an elliptical galaxy in
the Virgo constellation.', '[0,0,0,0,1]');
INSERT INTO galaxies VALUES (9, 'NGC1073', 'NGC 1073 is a barred spiral
galaxy in Cetus constellation.', '[0,1,1,0,0]');
COMMIT;





