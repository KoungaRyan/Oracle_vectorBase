import oracledb
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# Connexion Oracle
conn = oracledb.connect(user="ryan", password="ryan23", dsn="localhost:1521/FREEPDB1")
cursor = conn.cursor()

# Requête pour récupérer les phrases et vecteurs
cursor.execute("SELECT id, phrase, vector FROM fraud_text_vectors")
rows = cursor.fetchall()

# Phrase à analyser
phrase_input = input("Entrez une phrase à analyser :\n→ ")
model = SentenceTransformer('all-MiniLM-L6-v2')
query_vector = model.encode(phrase_input)

# Calcul des similarités
results = []
for row in rows:
    id, phrase, vector_oracle = row
    vector = np.array(vector_oracle, dtype=np.float32)
    score = cosine_similarity([query_vector], [vector])[0][0]
    
    # Ajout de l'étiquette
    label = "FRAUDE" if score > 0.6 else "NORMALE"
    results.append((score, phrase, label))

# Affichage des 5 plus similaires
results.sort(reverse=True)
print(" Résultats :")
for score, phrase, label in results[:5]:
    print(f"- {phrase}  (score: {score:.4f})  → {label}")


cursor.close()
conn.close()
