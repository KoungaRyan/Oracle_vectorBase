import oracledb
import json
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# Connexion Oracle
conn = oracledb.connect(user="nlp_user", password="nlp_pass", dsn="localhost:1521/FREEPDB1")
cursor = conn.cursor()

# Charger les données
cursor.execute("SELECT id, phrase, vector FROM nlp_vectors")
rows = cursor.fetchall()

# Entrée utilisateur
phrase_input = "l'IA va revolutioner le monde"
model = SentenceTransformer('all-MiniLM-L6-v2')
query_vector = model.encode(phrase_input)

# Similarités
similarities = []
for row in rows:
    id, phrase, vector_json = row 
    vector = json.loads(vector_json.read())
    sim = cosine_similarity([query_vector], [vector])[0][0]
    similarities.append((sim, phrase))

# Top résultats
similarities.sort(reverse=True)
print("Top phrases similaires :")
for score, phrase in similarities[:5]:
    print(f"{phrase} (score: {score:.4f})")

cursor.close()
conn.close()
