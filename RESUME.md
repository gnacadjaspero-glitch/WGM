# 🏆 WINNER GAME MANAGER (WGM) - RÉSUMÉ COMPLET DU SYSTÈME

Ce document présente l'intégralité des fonctionnalités et de l'architecture du système **Winner Game Manager**, une solution de gestion de salle de jeu haute performance alliant logiciel Flutter et matériel ESP32.

---

## 🎨 1. IDENTITÉ VISUELLE & DESIGN "PRESTIGE"
*   **Thème Néon Cyberpunk** : Interface sombre (#07131F) avec accents Cyan Néon et Bleu Profond.
*   **Design Glassmorphism** : Utilisation de bordures néon actives, de flous de profondeur et de dégradés pour une esthétique moderne.
*   **Rapports PDF Haute Fidélité** :
    *   En-tête tripartite avec logo circulaire HD (bordure Cyan).
    *   Centrage mathématique laser de la "RECETTE TOTALE".
    *   Typographie Bahnschrift pour un aspect technique et officiel.
    *   Tableaux de session structurés avec séparateurs de milliers (format prestige).
    *   **Garantie "Zéro Déformation"** : Utilisation de ratios d'aspect fixes (1:1) et `BoxFit.contain` pour empêcher tout étirement ou compression du logo sur les écrans et PDF.

---

## 🛡️ 2. SYSTÈME "BOÎTE NOIRE" (AUDIT & SÉCURITÉ)
Le système est conçu pour être inviolable par le personnel de gestion.
*   **Audit en Temps Réel** : Chaque action (connexion, lancement de session, arrêt) est enregistrée dans un journal texte horodaté.
*   **Rapports PDF Dynamiques** : Mise à jour instantanée du rapport de la journée à chaque encaissement.
*   **Stockage Furtif (Invisible)** :
    *   **Sur Windows** : Archives cachées dans `%AppData%/Roaming/Audit_Logs` (survit à la désinstallation).
    *   **Sur Android** : Archives cachées dans `Documents/.wgm_audit` (le "." masque le dossier, survit à la désinstallation).
*   **Zéro Trace UI** : Aucun bouton dans l'interface Gérant ou Admin ne permet d'accéder à ces dossiers ; seul le propriétaire (vous) connaît les chemins système.

---

## 🔌 3. SYNERGIE MATÉRIELLE (ESP32)
*   **Source de Vérité** : L'état du matériel (relais/TV) est synchronisé toutes les 5 secondes avec l'application.
*   **Sécurité des Commandes** : Toute instruction envoyée au boîtier ESP32 est verrouillée par une clé secrète complexe : `X9#kL2!vP5*qZ8$mN4@yT1`.
*   **Gestion des Coupures de Courant** : Intégration native du flag `isCoupure`. Si le courant revient, les sessions reprennent exactement là où elles s'étaient arrêtées (sauvegarde sur le matériel).
*   **Communication WiFi** : Gestion intelligente des déconnexions avec alertes visuelles.

---

## 🕹️ 4. FONCTIONNALITÉS OPÉRATIONNELLES (GÉRANT)
*   **Pilotage des Postes** : Vue d'ensemble de tous les postes avec état en temps réel (Actif/Libre).
*   **Gestion des Forfaits** : Sélection rapide de tarifs prédéfinis (ex: 1h, 2h, Nuit).
*   **Alertes Sonores & Visuelles** : Notification automatique lorsque le temps restant est inférieur à 5 minutes.
*   **Historique Local** : Consultation des dernières recettes de la session en cours.
*   **Verrouillage Session** : Empêche toute modification de tarif une fois la session lancée sans une action d'arrêt explicite.

---

## ⚙️ 5. ADMINISTRATION & CONFIGURATION
*   **Gestion des Postes** : Ajout, modification et suppression des postes de jeu.
*   **Grille Tarifaire Flexible** : Configuration personnalisée des durées (en minutes) et des prix pour chaque poste.
*   **Sécurité Admin** : Accès protégé par mot de passe pour la configuration système.
*   **Statistiques** : Calcul automatique des cumuls par poste et de la recette globale.

---

## 📦 6. DÉPLOIEMENT & PERSISTANCE
*   **Multi-Plateforme** : Code optimisé pour Windows (PC) et Android (Phone).
*   **Persistance Locale** : Utilisation de `SharedPreferences` pour une sauvegarde robuste des données de configuration même sans internet.
*   **Installateur Windows** : Script Inno Setup configuré pour un déploiement propre avec icône personnalisée et gestion des dépendances.

---
*Document certifié conforme - Système Winner Game Manager v2.0*
