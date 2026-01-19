import oracledb
import json
import numpy as np
from sentence_transformers import SentenceTransformer

# Connexion à la base de données
user = "ryan"
password = "ryan23"
dsn = "localhost:1521/FREEPDB1"  

# Crée une instance du modèle de phrase
model = SentenceTransformer('all-MiniLM-L6-v2')

# Liste des phrases à insérer
phrases = [
    "Votre transaction de 100€ a été validée.",
    "Appel urgent ! Mettez à jour vos informations bancaires pour éviter le blocage de votre compte.",
    "Votre virement de 250€ est en cours.",
    "Alerte de sécurité : une activité inhabituelle a été détectée sur votre compte.",
    "Merci de nous avoir contactés, votre demande est en cours de traitement.",
	"Votre virement de 500€ a été effectué avec succès.",
    "Merci pour votre paiement. Votre facture a bien été réglée.",
    "Votre demande de remboursement est en cours de traitement.",
    "Votre solde actuel est de 1 200€.",
    "Vous avez effectué un retrait de 100€ au distributeur.",
    "Votre carte bancaire expire dans 2 mois.",
    "Nous vous informons de la mise à jour des conditions générales.",
    "Votre prélèvement automatique EDF sera exécuté le 5 août.",
    "Nous avons bien enregistré votre changement d’adresse.",
    "Votre relevé de compte est disponible en ligne.",
    "Bonjour, nous vous confirmons la réception de votre dossier.",
    "Votre dossier a été transmis à notre service comptabilité.",
    "Votre abonnement sera renouvelé automatiquement le 1er septembre.",
    "Le prélèvement de votre loyer a bien été effectué.",
    "Votre carte de fidélité est activée.",
	"Votre carte bancaire a été bloquée, veuillez vérifier vos informations immédiatement.",
    "Une activité suspecte a été détectée sur votre compte, cliquez ici pour confirmer.",
    "Votre compte sera suspendu sous 24h si aucune action n’est prise.",
    "Vous avez gagné 1000€, entrez vos coordonnées bancaires pour recevoir le paiement.",
    "Confirmation urgente requise : accédez à votre espace client ici.",
    "Code de sécurité invalide ! Veuillez vous reconnecter immédiatement.",
    "Vous avez reçu un virement important, ouvrez la pièce jointe pour plus de détails.",
    "Votre identifiant est compromis. Cliquez sur ce lien sécurisé pour le réinitialiser.",
    "Nous avons besoin d'une vérification d'identité pour éviter la suppression de votre compte.",
    "Alerte : tentative de retrait non autorisé. Connectez-vous pour annuler.",
    "Votre facture impayée doit être régularisée aujourd’hui.",
    "Merci de valider votre paiement en cliquant ici.",
    "Nous avons détecté une anomalie sur votre prélèvement automatique.",
    "Une erreur s’est produite sur votre virement, reprogrammez-le maintenant.",
    "Paiement refusé : mettez à jour vos coordonnées bancaires.",
    "Nous sommes PayPal. Votre compte est restreint pour raison de sécurité.",
    "Bonjour, ici votre conseiller bancaire. Merci de transmettre votre RIB au plus vite.",
    "L’accès à votre dossier est bloqué. Réactivez-le en vérifiant votre identité.",
    "Vos données personnelles ont été compromises. Téléchargez ce document pour en savoir plus.",
    "Microsoft : votre licence a expiré. Renouvelez-la maintenant pour éviter la perte de données.",
	"Votre relevé de compte est disponible dans votre espace client.",
    "Merci pour votre paiement, votre facture a bien été réglée.",
    "Votre commande a été expédiée et arrivera sous 3 jours ouvrés.",
    "Nous avons bien reçu votre demande de remboursement.",
    "Votre prélèvement EDF sera effectué le 5 août.",
    "Bonjour, nous vous remercions de votre fidélité.",
    "Votre message a bien été transmis à notre service client.",
    "Merci de nous avoir contactés, nous reviendrons vers vous sous 48h.",
    "Nous vous confirmons la réception de votre dossier.",
    "Votre abonnement a été renouvelé avec succès.",
    "Votre virement de 250€ a été validé avec succès.",
    "Votre solde actuel est de 1 200€ au 10 juillet.",
    "Vous avez effectué un retrait de 100€ au distributeur.",
    "Votre carte bancaire expirera dans 2 mois.",
    "Votre identifiant client a été mis à jour.",
    "Nous vous informons d’un changement dans nos conditions générales.",
    "Votre dossier a été transféré au service comptabilité.",
    "Votre adresse postale a bien été mise à jour.",
    "Votre relevé fiscal est désormais disponible.",
    "Nous vous remercions pour votre commande."
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
    sql = "INSERT INTO fraud_text_vectors (id, phrase, vector) VALUES (nlp_seq.NEXTVAL, :1, :2)"
    cursor.execute(sql, [phrase, vector_str])

# Validation de la transaction
connection.commit()

print("✅ Insertion terminée avec succès.")

# Fermeture
cursor.close()
connection.close()
