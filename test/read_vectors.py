import oracledb
import json

# Connexion à la base Oracle
connection = oracledb.connect(
    user="nlp_user",
    password="nlp_pass",
    dsn="localhost:1521/FREEPDB1"
)

cursor = connection.cursor()

# Lecture des lignes
cursor.execute("SELECT id, phrase, vector FROM nlp_vectors")
rows = cursor.fetchall()

for row in rows:
    id, phrase, vector_clob = row

    # Lire le contenu du CLOB
    vector_json_str = vector_clob.read() 
    vector = json.loads(vector_json_str)

    print(f"ID: {id} | Phrase: {phrase} | Vector (dim {len(vector)}): {vector}")

cursor.close()
connection.close()
