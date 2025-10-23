import streamlit as st
import oracledb
import json
import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt

# Configuration Streamlit
st.set_page_config(page_title="🔍 Recherche NLP Oracle", layout="wide")
model = SentenceTransformer("all-MiniLM-L6-v2")

# Connexion Oracle
@st.cache_resource
def get_connection():
    return oracledb.connect(
        user="nlp_user",
        password="nlp_pass",
        dsn="localhost:1521/FREEPDB1"
    )

conn = get_connection()
cursor = conn.cursor()

# Chargement des données
def load_data():
    cursor.execute("SELECT id, phrase, vector FROM nlp_vectors")
    rows = cursor.fetchall()
    ids, phrases, vectors = [], [], []
    for row in rows:
        ids.append(row[0])
        phrases.append(row[1])
        vectors.append(json.loads(row[2].read()))
    return ids, phrases, np.array(vectors).astype("float32")

# Recherche vectorielle
def search_similar(query_vector, vectors, k=5):
    scores = cosine_similarity(query_vector, vectors)[0]
    top_idx = np.argsort(scores)[::-1][:k]
    return top_idx, scores[top_idx]

# Graphique PCA pour résultats similaires uniquement
def plot_pca(result_vectors, result_phrases, query_vector):
    all_vectors = np.vstack([result_vectors, query_vector])
    reduced = PCA(n_components=2).fit_transform(all_vectors)
    fig, ax = plt.subplots()
    ax.scatter(reduced[:-1, 0], reduced[:-1, 1], label="Résultats similaires", color='blue')
    ax.scatter(reduced[-1, 0], reduced[-1, 1], label="Requête", color='red')
    for i, phrase in enumerate(result_phrases + ["(Votre requête)"]):
        ax.annotate(phrase, (reduced[i, 0], reduced[i, 1]), fontsize=7)
    ax.legend()
    st.pyplot(fig)

# Insertion de phrase
def insert_phrase(phrase, vector):
    cursor.execute("INSERT INTO nlp_vectors (phrase, vector) VALUES (:1, :2)", [phrase, json.dumps(vector)])
    conn.commit()

# Vérification de l'existence d'un ID
def id_exists(phrase_id):
    cursor.execute("SELECT COUNT(*) FROM nlp_vectors WHERE id = :id", [phrase_id])
    result = cursor.fetchone()
    return result[0] > 0

# Suppression avec ID
def delete_by_id(phrase_id):
    cursor.execute("DELETE FROM nlp_vectors WHERE id = :id", [phrase_id])
    conn.commit()

# Interface utilisateur
st.title("🧠 Recherche Sémantique avec Oracle")

tab1, tab2, tab3 = st.tabs(["🔎 Recherche", "➕ Ajouter une phrase", "🗑️ Supprimer une phrase"])

# --- Onglet Recherche
with tab1:
    st.subheader("🔍 Recherche de similarité sémantique")
    ids, phrases, vectors = load_data()
    query = st.text_input("Entrez une phrase à rechercher")
    
    if query:
        q_vec = model.encode(query).astype("float32").reshape(1, -1)
        top_idx, scores = search_similar(q_vec, vectors, k=5)

        st.subheader("📋 Résultats")
        results = []
        for i, idx in enumerate(top_idx):
            results.append((ids[idx], phrases[idx], float(scores[i])))
            st.markdown(f"- ID: `{ids[idx]}` | **{phrases[idx]}** | Score : `{scores[i]:.4f}`")

        # Export CSV
        df = pd.DataFrame(results, columns=["ID", "Phrase", "Score"])
        st.download_button("📥 Télécharger CSV", df.to_csv(index=False).encode("utf-8"), "resultats.csv", "text/csv")

        # Visualisation PCA (requête + résultats)
        st.subheader("📊 Visualisation PCA")
        result_vectors = vectors[top_idx]
        result_phrases = [phrases[idx] for idx in top_idx]
        plot_pca(result_vectors, result_phrases, q_vec)

# --- Onglet Ajout
with tab2:
    st.subheader("➕ Ajouter une nouvelle phrase")
    new_phrase = st.text_input("Nouvelle phrase")
    if st.button("Ajouter"):
        if new_phrase.strip():
            vec = model.encode(new_phrase).tolist()
            insert_phrase(new_phrase, vec)
            st.success("✅ Phrase ajoutée à la base.")
        else:
            st.warning("❗ Phrase vide.")

# --- Onglet Suppression
with tab3:
    st.subheader("🗑️ Supprimer une phrase")
    del_id = st.text_input("Entrez l’ID de la phrase à supprimer")
    
    if st.button("Supprimer"):
        if del_id.strip().isdigit():
            phrase_id = int(del_id.strip())
            if id_exists(phrase_id):
                try:
                    delete_by_id(phrase_id)
                    st.success(f"✅ Phrase ID {phrase_id} supprimée.")
                except Exception as e:
                    st.error(f"❌ Erreur lors de la suppression : {e}")
            else:
                st.warning(f"⚠️ L’ID {phrase_id} n’existe pas dans la base.")
        else:
            st.warning("❗ Veuillez entrer un ID valide (nombre entier).")

    # Affichage des phrases
    st.subheader("📄 Phrases enregistrées")
    ids, phrases, _ = load_data()
    df_all = pd.DataFrame({"ID": ids, "Phrase": phrases})
    st.dataframe(df_all)
