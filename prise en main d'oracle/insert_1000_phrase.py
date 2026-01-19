import oracledb
import json
import numpy as np
from sentence_transformers import SentenceTransformer
import random
from multiprocessing import Pool, cpu_count

# Configuration
user = "nlp_user"
password = "nlp_pass"
dsn = "localhost:1521/FREEPDB1"

# Crée une instance du modèle une seule fois (partagé par les workers)
model = SentenceTransformer('all-MiniLM-L6-v2')

# Base de phrases
base_phrases = [
    "Bonjour, comment ça va ?",
    "L'intelligence artificielle transforme le monde.",
    "Le traitement du langage naturel est fascinant.",
    "Les vecteurs sont utilisés pour comparer des phrases.",
    "Oracle 23c supporte les données vectorielles.",
    "La science des données devient incontournable.",
    "Python est très utilisé en data science.",
    "Le machine learning est une branche de l’IA.",
    "Les réseaux de neurones imitent le cerveau humain.",
    "Streamlit permet de créer des interfaces rapidement.",
    "Les données sont le nouveau pétrole.",
    "ChatGPT est un modèle de langage impressionnant.",
    "Les bases de données vectorielles gagnent en popularité.",
    "Un modèle pré-entraîné peut être fine-tuné.",
    "L’API Hugging Face est très pratique pour les projets NLP.",
    "La similarité sémantique est utile pour la recherche de texte.",
    "La PCA est une méthode de réduction de dimension.",
    "FAISS est rapide pour les recherches de vecteurs.",
    "L’oracle SQL Developer est un outil graphique puissant.",
    "Les embeddings capturent la signification des phrases.",
    "Un pipeline NLP contient plusieurs étapes de traitement.",
    "L’analyse de sentiment est une tâche courante.",
    "Transformer est une architecture révolutionnaire.",
    "BERT est l’un des modèles les plus connus.",
    "OpenAI développe des outils pour les développeurs.",
    "Un data lake centralise les données d’entreprise.",
    "MongoDB est une base NoSQL populaire.",
    "Spark est utilisé pour le traitement de données massives.",
    "Hadoop permet le stockage distribué.",
    "Une requête SQL peut extraire des insights.",
    "Les modèles multilingues supportent plusieurs langues.",
    "La vectorisation est une étape clé en NLP.",
    "L’optimisation des hyperparamètres améliore les modèles.",
    "Un fichier CSV est souvent utilisé pour exporter les résultats.",
    "Oracle peut stocker des JSON et des vecteurs.",
    "L’indexation vectorielle est utile pour la recherche rapide.",
    "L’apprentissage supervisé utilise des données étiquetées.",
    "L’apprentissage non supervisé découvre des patterns.",
    "K-means est une méthode de clustering simple.",
    "Le deep learning nécessite beaucoup de données.",
    "Une visualisation aide à comprendre les résultats.",
    "Pandas est une librairie utile pour manipuler les données.",
    "Matplotlib permet de tracer des graphiques.",
    "Les chatbots utilisent souvent le NLP.",
    "Générer un résumé automatique est un défi intéressant.",
    "Traduire des textes est une autre tâche du NLP.",
    "L’analyse syntaxique examine la structure des phrases.",
    "Un modèle entraîné peut être déployé sur le cloud.",
    "LangChain permet de créer des chaînes de modèles NLP.",
    "La sécurité des données est essentielle dans les projets IA."
]

# Génère 1000 phrases uniques
def generate_phrases(n=1000):
    return [f"{random.choice(base_phrases)} [Exemple {i+1}]" for i in range(n)]

# Fonction pour insérer une phrase (appelée en parallèle)
def insert_phrase(phrase):
    try:
        # Connexion isolée pour chaque process
        conn = oracledb.connect(user=user, password=password, dsn=dsn)
        cursor = conn.cursor()

        vector = model.encode(phrase)
        vector_str = json.dumps(vector.tolist())
        sql = "INSERT INTO nlp_vectors (id, phrase, vector) VALUES (nlp_vectors_seq.NEXTVAL, :1, :2)"
        cursor.execute(sql, [phrase, vector_str])
        conn.commit()

        cursor.close()
        conn.close()
        return f"✅ {phrase[:40]}... insérée."
    except Exception as e:
        return f"❌ Erreur sur '{phrase[:40]}...': {str(e)}"

if __name__ == "__main__":
    phrases = generate_phrases(1000)

    # Utilisation de tous les cœurs CPU
    with Pool(cpu_count()) as pool:
        results = pool.map(insert_phrase, phrases)

    for res in results:
        print(res)

    print("✅ Insertion parallèle terminée.")
