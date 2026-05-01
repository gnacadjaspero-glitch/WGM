# Documentation Système : Winner Game Manager (WGM)

## 1. Architecture Globale
Le système repose sur une architecture **Maître-Miroir** où le matériel (ESP32) est l'unique source de vérité.

*   **Le Boîtier (ESP32)** : Le Maître. Il détient le temps réel et contrôle l'énergie (Relais).
*   **L'Application (Flutter)** : Le Miroir. Elle sert d'interface de commande et de prédiction visuelle.

---

## 2. Rôle du Boîtier (Le Cerveau Matériel)
L'ESP32 fonctionne de manière totalement autonome une fois la session lancée.

*   **Hôte Réseau (Access Point)** : Il émet son propre WiFi ("WGM") et gère les connexions sans routeur externe.
*   **Contrôle Physique** : Gère l'ouverture et la fermeture des circuits électriques via des relais.
*   **Gardien du Temps** : Le décompte des minutes se fait en interne. Même si l'application est fermée ou le PC s'éteint, le boîtier coupera le poste exactement à la fin du temps imparti.
*   **Sécurité (Key Validation)** : Il rejette toute commande qui ne contient pas la clé secrète complexe (`X9#kL2!vP5*qZ8$mN4@yT1`), empêchant ainsi tout piratage par un client connecté au WiFi.
*   **Serveur de Statut** : Il renvoie en permanence le temps exact restant pour chaque poste.

---

## 3. Rôle de l'Application (L'Interface de Gestion)
L'application simplifie le travail du gérant et assure le suivi commercial.

*   **Pilotage Temps Réel** : Permet d'envoyer les ordres d'activation et de stop.
*   **Mode "Miroir" (Local Prediction)** : Pour éviter les saccades dues au réseau, l'app prédit le décompte seconde par seconde localement, mais se **recalibre sur le boîtier toutes les 5 secondes**.
*   **Gestion Commerciale** :
    *   Configuration des tarifs et forfaits.
    *   Calcul et stockage des recettes journalières.
    *   Historique des sessions par poste.
*   **Sécurité Préventive** : Bloque les boutons d'action si le PC n'est pas connecté au réseau "WGM".

---

## 4. Flux de Communication (Cycle de Vie)
1.  **Connexion** : Le PC se connecte au WiFi "WGM" (IP Fixe: `192.168.100.1`).
2.  **Commande** : L'App envoie `/activate?id=P1&time=60&key=...`.
3.  **Action** : Le Boîtier active le relais et démarre son chrono interne.
4.  **Synchronisation** : Toutes les 5s, l'App demande `/status`. Si le boîtier dit "Il reste 54min", l'App ajuste son affichage.
5.  **Fin** : Arrivé à 0, le Boîtier coupe le relais. L'App détecte la fin au prochain cycle de 5s et archive la session.

---

## 5. Gestion des Coupures (Principe de la Pause)
Le système protège le temps de jeu effectif du client. En cas de coupure, le chrono est considéré comme étant en "PAUSE".

*   **Mémoire de Crédit** : Le boîtier n'enregistre pas l'heure de fin, mais le **temps restant** (en secondes) dans la mémoire du RTC.
*   **Exemple de Compensation** : 
    *   Un joueur paye 1h (60 min) à 14h00.
    *   Coupure à 14h15 (il a joué 15 min, il lui reste 45 min).
    *   Le courant revient à 14h30 ou même 16h00 : le boîtier propose de reprendre les **45 minutes** restantes.
*   **Seuil de 10 minutes** : Si au moment de la coupure il restait moins de 10 minutes, la session est annulée par sécurité.
*   **Reprise Manuelle (tv_coupure.png)** : Le boîtier attend que le gérant valide la présence du joueur avant de relancer le relais.

## 6. Spécifications Techniques
*   **SSID WiFi** : `WGM`
*   **Password WiFi** : `CheatWinner@360`
*   **IP Boîtier** : `192.168.100.1`
*   **Clé de Sécurité API** : `X9#kL2!vP5*qZ8$mN4@yT1`
*   **Fréquence de Sync** : 5 secondes.
