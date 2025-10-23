import oracledb
import json
import numpy as np
from sentence_transformers import SentenceTransformer

# Connexion à la base de données
user = "nlp_user"
password = "nlp_pass"
dsn = "localhost:1521/FREEPDB1"  

# Crée une instance du modèle de phrase
model = SentenceTransformer('all-MiniLM-L6-v2')

# Liste des phrases à insérer
phrases = [
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

# Connexion à la base Oracle
connection = oracledb.connect(user=user, password=password, dsn=dsn)
cursor = connection.cursor()

# Boucle d'insertion
for phrase in phrases:
    # Génération du vecteur
    vector = model.encode(phrase)
    vector_str = json.dumps(vector.tolist())  # Conversion en texte JSON

    # Insertion dans la base
    sql = "INSERT INTO nlp_vectors (id, phrase, vector) VALUES (nlp_seq.NEXTVAL, :1, :2)"
    cursor.execute(sql, [phrase, vector_str])

# Validation de la transaction
connection.commit()

print("✅ Insertion terminée avec succès.")

# Fermeture
cursor.close()
connection.close()
