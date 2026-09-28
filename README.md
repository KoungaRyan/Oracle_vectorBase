# Bases de données vectorielles avec Oracle Database 23ai

Étude et mise en œuvre des **fonctionnalités vectorielles d'Oracle Database 23ai (AI Vector Search)** : stockage d'embeddings dans des colonnes `VECTOR`, index vectoriels et **recherche de similarité en SQL**. Le projet va de la prise en main d'Oracle jusqu'à un cas d'usage complet : un **outil d'aide à la décision médicale** intégré dans une architecture **Data Lake**, qui recommande des traitements à partir de cas de patients similaires (textes) et retrouve des images rétiniennes proches (images).

> Projet de mémoire réalisé à l'**ESSFAR** sous la supervision du **Dr Gabriel Mopolo** (2025-2026).

---

## Sommaire

1. [Résultats](#résultats)
2. [Architecture du Data Lake](#architecture-du-data-lake)
3. [Structure du dépôt](#structure-du-dépôt)
4. [Partie 1 — Prise en main d'Oracle 23ai](#partie-1--prise-en-main-doracle-23ai)
5. [Partie 2 — Cas d'usage médical](#partie-2--cas-dusage-médical)
6. [Installation](#installation)
7. [Documentation](#documentation)

---

## Résultats

Recherche des **10 plus proches voisins** (k-NN, similarité cosinus) exécutée directement dans Oracle :

| Critère | Texte (cas patients) | Images (rétines) |
|---|---|---|
| Nombre de vecteurs | 11 049 | ~1 500 |
| Dimension | 768 | 512 |
| Modèle d'embedding | BioBERT (Sentence Transformers) | CLIP ViT-B/32 |
| Temps moyen d'une requête | **256 ms** | **93 ms** |
| Temps min – max | 183 – 609 ms | 43 – 227 ms |
| Precision@10 | **0.85** | **0.80** |

Oracle 23ai répond en quelques centaines de millisecondes sur plus de 11 000 vecteurs de grande dimension, avec des résultats pertinents dans environ 8 cas sur 10. Il peut donc servir de moteur vectoriel intégré, sans base spécialisée à côté du SGBD relationnel.

*Source : tableau de synthèse du mémoire final ; Precision@10 évaluée manuellement.*

---

## Architecture du Data Lake

```
 ┌──────────────────────── SOURCES ────────────────────────┐
 │  Healthcare Dataset   │  Cas patients      │  Images     │
 │  (Kaggle, CSV)        │  (CSV synthétiques)│  rétiniennes│
 └──────────┬────────────┴─────────┬──────────┴──────┬──────┘
            │                      │                 │
     Apache Hop (ETL)              │                 │
            │                      │                 │
          MySQL                    │                 │
            │                      │                 │
  ODBC + dg4odbc                   │                 │
  (database link)          BioBERT (768-d)    CLIP ViT-B/32 (512-d)
            │                      │                 │
 ┌──────────▼──────────────────────▼─────────────────▼──────┐
 │                   ORACLE DATABASE 23ai                    │
 │  healthcare_view │ patient_cases / new_patient │          │
 │  (via mysql_link)│ VECTOR(768, FLOAT32)        │ diabetic_│
 │                  │                             │ retinopathy_diagnosis
 │                  │                             │ BLOB + VECTOR(512)
 └───────────────────────────┬──────────────────────────────┘
                             │  VECTOR_DISTANCE(..., COSINE)
                             ▼
          Recherche de similarité · PCA · K-Means · DBSCAN
```

| Brique | Rôle |
|---|---|
| **Apache Hop** | Pipeline ETL `Data_Extraction.hpl` : CSV Healthcare → table MySQL |
| **MySQL** (XAMPP) | Base intermédiaire des données tabulaires |
| **ODBC + dg4odbc** | Passerelle hétérogène : Oracle lit MySQL via le database link `mysql_link` |
| **Oracle 23ai** | Stockage centralisé des données, des vecteurs et des images (BLOB) ; calcul des distances en SQL |
| **Python** | Génération des embeddings et insertion avec `oracledb` |

---

## Structure du dépôt

```
Oracle_vectorBase-main/
├── prise en main d'oracle/        # Partie 1 — découverte des vecteurs Oracle
│   ├── Demo.sql                   # Utilisateur, type VECTOR, vecteurs denses/sparse
│   ├── nouveau 1.txt              # Brouillon de Demo.sql
│   ├── fraude_detaction.sql       # Cas fraude : table, index vectoriel, distances
│   ├── insert_vectors.py          # Insertion de 60 messages bancaires vectorisés
│   ├── detect.py                  # Détection de messages frauduleux par similarité
│   ├── insert_vectors1.py         # Insertion de 50 phrases NLP
│   ├── insert_1000_phrase.py      # Insertion parallèle de 1 000 phrases
│   ├── read_vectors.py            # Lecture des vecteurs stockés
│   ├── similarity.py              # Recherche des phrases les plus proches
│   └── vector_app.py              # Application Streamlit de recherche sémantique
│
├── use case medical/              # Partie 2 — Data Lake médical
│   ├── medical_note.txt           # Description du cas d'usage
│   ├── Data_Extraction.hpl        # Pipeline Apache Hop (CSV → MySQL)
│   ├── performance_metric.ipynb   # Graphiques de performance
│   ├── data/
│   │   ├── healthcare_dataset.csv.zip   # Healthcare Dataset (Kaggle)
│   │   ├── patient_data_utf8.csv        # 50 cas patients rédigés
│   │   ├── patient_synthetic_*.csv      # Cas patients synthétiques (1 000 à 10 000)
│   │   ├── new_patient_data_utf8.csv    # 10 nouveaux patients à comparer
│   │   └── dataclass.rar                # Images de test
│   └── script et code/
│       ├── Creation MyQSL tables.sql
│       ├── Database_link.sql            # Database link Oracle → MySQL
│       ├── Text_data_treatment.ipynb    # Génération, vectorisation et insertion des textes
│       ├── img_data treatment.ipynb     # Vectorisation CLIP et insertion des images
│       ├── video_data_treatment.ipynb   # Exploration : vidéo (CLIP) et audio (Wav2Vec2)
│       ├── Data_Text_image_Exploration.ipynb  # PCA, K-Means, DBSCAN
│       ├── Text_query_similarity_search.sql
│       ├── Patient_case_query.sql
│       ├── img_query.sql
│       └── img_query_similsrity_search.sql
│
├── Rapport/                       # Mémoire (versions successives) et rapport d'installation
├── compte rendu/                  # Comptes rendus de réunion, architecture du Data Lake
└── planning du projet/            # Planning (PDF)
```

---

## Partie 1 — Prise en main d'Oracle 23ai

### Le type `VECTOR`

```sql
CREATE TABLE my_vect_tab (v01 VECTOR(3, INT8));
INSERT INTO my_vect_tab VALUES ('[10, 20, 30]');

-- Vecteurs creux (sparse) : [dimension, [indices], [valeurs]]
CREATE TABLE my_sparse_tab (v01 VECTOR(5, INT8, SPARSE));
INSERT INTO my_sparse_tab VALUES ('[5,[2,4],[10,20]]');
```

`Demo.sql` couvre aussi la conversion dense ↔ sparse (`TO_VECTOR`, `FROM_VECTOR`) et une table d'exemple `galaxies`.

### Mini cas d'usage : détection de messages frauduleux

1. `fraude_detaction.sql` crée la table `fraud_text_vectors (phrase, vector VECTOR(384))`.
2. `insert_vectors.py` vectorise 60 messages bancaires, légitimes ou de type phishing, avec **all-MiniLM-L6-v2**.
3. `detect.py` compare un message saisi aux messages stockés : au-delà d'une similarité de 0,6, il est étiqueté **FRAUDE**.

Le script SQL montre aussi :

- la création d'un **index vectoriel HNSW en mémoire** (`ORGANIZATION INMEMORY NEIGHBOR GRAPH`, `DISTANCE COSINE`, `TARGET ACCURACY 95`) ;
- une **fonction de distance personnalisée** écrite en JavaScript (MLE) et utilisée par un index.

### Application Streamlit — `vector_app.py`

Interface de recherche sémantique sur la table `nlp_vectors`, avec trois onglets :

- **Recherche** : top 5 des phrases les plus proches, export CSV, projection **PCA** de la requête et des résultats ;
- **Ajout** d'une phrase (vectorisée à la volée) ;
- **Suppression** par identifiant.

```bash
streamlit run "prise en main d'oracle/vector_app.py"
```

---

## Partie 2 — Cas d'usage médical

### Objectif

Quand un nouveau patient arrive, on vectorise la description de ses symptômes, on cherche dans Oracle les **cas passés les plus proches**, puis on affiche **les traitements prescrits et leur résultat** (Success / Partial / Failure). Le médecin s'appuie ainsi sur l'expérience accumulée dans les dossiers.

### Données textuelles

- **`patient_cases`** : 11 049 cas (description, traitement, résultat), vectorisés avec **`pritamdeka/BioBERT-mnli-snli-scinli-scitail-mednli-stsb`** (768 dimensions, spécialisé en biomédical)
- **`new_patient`** : nouveaux cas à comparer

```sql
SELECT np.description        AS nouveau_patient,
       p.description         AS cas_similaire,
       p.traitement_prescrit AS traitement,
       p.outcome,
       ROUND(VECTOR_DISTANCE(p.vector, np.vector, COSINE), 2) AS distance
FROM   patient_cases p
CROSS  JOIN new_patient np
WHERE  np.id = 1
ORDER  BY VECTOR_DISTANCE(p.vector, np.vector, COSINE)
FETCH  FIRST 5 ROWS ONLY;
```

`Patient_case_query.sql` compare aussi les distances **EUCLIDEAN**, **MANHATTAN**, **DOT** et **COSINE** sur la même requête.

### Données images

- **`diabetic_retinopathy_diagnosis`** : ~1 500 images rétiniennes du dataset *Diabetic Retinopathy Diagnosis* (Kaggle), stockées en **BLOB** avec leur embedding **CLIP** (`openai/clip-vit-base-patch32`, 512 dimensions)
- Requête : les 10 images les plus proches d'une image de référence (`img_query_similsrity_search.sql`)

### Analyses complémentaires

`Data_Text_image_Exploration.ipynb` récupère les vecteurs depuis Oracle et applique :

- une **PCA** pour visualiser les vecteurs en 2D ;
- **K-Means** (avec méthode du coude) et **DBSCAN** pour regrouper des patients aux profils similaires.

`video_data_treatment.ipynb` explore l'extension à d'autres types de données : images extraites d'une vidéo (CLIP) et piste audio (Wav2Vec2).

---

## Installation

### Prérequis

- **Oracle Database 23ai Free** (base enfichable `FREEPDB1`)
- Python ≥ 3.9
- Pour le Data Lake : MySQL (XAMPP), **Apache Hop**, pilote **MySQL ODBC** et passerelle `dg4odbc`

### Dépendances Python

```bash
pip install oracledb sentence-transformers transformers torch scikit-learn \
            numpy pandas matplotlib pillow streamlit
# optionnel (vidéo / audio)
pip install opencv-python moviepy soundfile
```

### Base de données

```sql
-- en tant qu'administrateur
CREATE USER ryan IDENTIFIED BY "<mot_de_passe>";
GRANT CONNECT, RESOURCE TO ryan;
ALTER USER ryan QUOTA UNLIMITED ON USERS;
```

Connexion depuis Python :

```python
import oracledb
conn = oracledb.connect(user="ryan", password="<mot_de_passe>", dsn="localhost:1521/FREEPDB1")
```

### Ordre d'exécution du cas médical

1. Charger le Healthcare Dataset dans MySQL avec `Data_Extraction.hpl`, puis créer le database link (`Database_link.sql`).
2. Créer les tables Oracle (`Text_query_similarity_search.sql`, `img_query_similsrity_search.sql`).
3. Vectoriser et insérer les textes (`Text_data_treatment.ipynb`) puis les images (`img_data treatment.ipynb`).
4. Lancer les requêtes de similarité SQL et les analyses (`Data_Text_image_Exploration.ipynb`).
---

## Documentation

Le dossier `Rapport/Rapport final/` contient le **mémoire complet** : concepts des bases vectorielles, état de l'art comparatif (**Oracle AI Vector, pgvector, Weaviate, FAISS**), installation d'Oracle 23ai, prise en main, Data Lake et évaluation des performances. Les comptes rendus de réunion et les schémas d'architecture se trouvent dans `compte rendu/`.

---

## Technologies

Oracle Database 23ai (AI Vector Search) · SQL · Python · oracledb · Sentence Transformers (BioBERT, MiniLM) · CLIP · Streamlit · scikit-learn · Apache Hop · MySQL · ODBC

## Auteur

**Ryan Kounga Tchomnou** — [@KoungaRyan](https://github.com/KoungaRyan)
