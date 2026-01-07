# Djim Search 🌐

**Djim Search** est un navigateur web mobile moderne, rapide et intuitif développé avec Flutter. Il offre une expérience de navigation épurée avec des fonctionnalités de recherche vocale et une interface utilisateur fluide inspirée des standards actuels.

Développé par **Panasoft Corporation**.

## 📱 Fonctionnalités Principales

### 🔍 Navigation & Recherche
- **Moteur de recherche intégré** : Utilise Google comme moteur par défaut.
- **Recherche Vocale** : Effectuez vos recherches simplement en parlant grâce à l'intégration `speech_to_text`.
- **Suggestions intelligentes** : Auto-complétion et suggestions de recherche en temps réel via l'API Google Suggest.
- **Interface Web Épurée** : Injection de JavaScript personnalisé pour masquer les éléments superflus (en-têtes/pieds de page Google) lors de la navigation pour une expérience "Plein écran".

### 🚀 Expérience Utilisateur (UX)
- **Gestion des Onglets** : Ouverture de nouvelles instances de navigation (Nouvel onglet) avec animation fluide.
- **Navigation Complète** : Boutons Précédent, Suivant, Actualiser et Accueil intégrés dans la barre d'outils.
- **Bouton Flottant (FAB)** : Bouton de rechargement accessible en bas d'écran lors de la navigation.
- **Animations Fluides** : Transitions personnalisées (Slide & Fade) entre les écrans.

### ⚙️ Menus & Paramètres
- **Écran Paramètres** : Interface moderne (style Chrome) avec sections (Compte, De base, Avancé).
- **Écran À Propos** : Informations sur l'application et visualisation des **Licences Open Source** avec une interface personnalisée.
- **Authentification** : Écrans de Connexion et de Création de compte (Interface UI).

## 🛠️ Technologies Utilisées

Ce projet est construit avec **Flutter** et utilise les packages suivants :

*   **[webview_flutter](https://pub.dev/packages/webview_flutter)** : Pour l'affichage des pages web.
*   **[http](https://pub.dev/packages/http)** : Pour les requêtes API (suggestions de recherche).
*   **[speech_to_text](https://pub.dev/packages/speech_to_text)** : Pour la reconnaissance vocale.
*   **[permission_handler](https://pub.dev/packages/permission_handler)** : Pour la gestion des permissions (micro).

## 📸 Captures d'écran

*(Espace réservé pour vos captures d'écran : Accueil, Résultats de recherche, Paramètres)*

## 🚀 Installation

1.  Clonez le dépôt :
    ```bash
    git clone https://github.com/votre-repo/djimsearch.git
    ```
2.  Installez les dépendances :
    ```bash
    flutter pub get
    ```
3.  Lancez l'application :
    ```bash
    flutter run
    ```

## 📝 Configuration requise

*   **Android** : SDK min 21 (recommandé).
*   **iOS** : Configuration standard Flutter (nécessite l'ajout des permissions micro dans Info.plist).

## 📄 Licence

Copyright © **Panasoft Corporation**. Tous droits réservés.
