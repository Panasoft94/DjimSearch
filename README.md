# DjimSearch 🌐

<p align="center">
  <img src="assets/img/logo.png" width="100" alt="DjimSearch Logo"/>
</p>

<p align="center">
  <strong>Navigateur web mobile intelligent & moderne</strong><br/>
  Développé avec Flutter par <strong>Panasoft Corporation</strong> 🇨🇫
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/flutter-3.9+-02569B?style=flat-square&logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/dart-3.9+-0175C2?style=flat-square&logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-green?style=flat-square" alt="Platform"/>
  <img src="https://img.shields.io/badge/licence-propriétaire-red?style=flat-square" alt="Licence"/>
</p>

---

## ✨ Présentation

**DjimSearch** est un navigateur web mobile rapide, sécurisé et intuitif. Il offre une expérience de navigation épurée avec recherche vocale, gestion avancée des onglets, personnalisation complète de l'interface et une architecture pensée pour la performance.

---

## 📱 Fonctionnalités

### 🔍 Recherche & Navigation
- **Moteur de recherche intégré** — Google par défaut, avec support Bing, DuckDuckGo et Yahoo
- **Recherche vocale** — Dictée en français avec reconnaissance `speech_to_text`
- **Suggestions intelligentes** — Auto-complétion en temps réel via Google Suggest (debounce 350ms)
- **Navigation URL directe** — Saisissez une URL complète (http/https) pour y accéder directement
- **Interface web épurée** — Injection JavaScript avancée (5 couches) pour masquer les éléments superflus de Google (headers, sticky bars, footers)

### 🎨 Personnalisation de l'Interface
- **Position de la barre de recherche** — Mode **Haut** (classique) ou **Bas** (style Comet) avec basculement instantané
- **Mode Bas (Comet)** :
  - Barre de recherche + navigation + menu en bas de l'écran
  - Logo et titre masqués automatiquement sur l'écran d'accueil
  - Plus d'espace pour le contenu et la navigation au pouce
  - Suggestions affichées au-dessus de la barre
  - Le clavier pousse la barre vers le haut (pas de masquage)
- **Toggle rapide** depuis le menu `⋮` ou dans Paramètres > Position barre de recherche

### 📂 Groupes d'Onglets
- **Création de groupes** — Organisez vos sessions de navigation par thème
- **Groupe actif** — Activez un groupe pour y sauvegarder automatiquement les onglets visités
- **Gestion complète** — Visualisation, suppression et navigation dans les groupes
- **Indicateur visuel** — Badge du groupe actif visible en permanence (barre du haut ou du bas)

### 📜 Historique & Téléchargements
- **Historique intelligent** — Sauvegarde automatique des recherches avec dédoublication
- **Écran historique dédié** — Recherche et sélection rapide depuis l'historique
- **Gestionnaire de téléchargements** — Suivi des fichiers téléchargés avec métadonnées

### 🧭 Navigation Avancée
- **Boutons Précédent / Suivant** — Navigation web intégrée dans la barre d'outils
- **Nouvel onglet** — Ouverture de nouvelles instances avec transition fluide
- **Bouton de rechargement** — FAB flottant en cas d'erreur de chargement
- **Gestion des erreurs** — Messages contextuels (DNS, timeout, URL invalide, blocage)
- **Barre de progression** — Indicateur linéaire de chargement en haut de l'écran

### ⚙️ Paramètres
- **Moteur de recherche** — Choix entre Google, Bing, DuckDuckGo, Yahoo
- **Position barre de recherche** — Haut ou Bas
- **Thème** — Clair, Sombre ou Système
- **Confidentialité** — Effacement de l'historique de navigation
- **Compte & Synchronisation** — Connexion / déconnexion avec sauvegarde de session

### 🔐 Compte Utilisateur
- **Création de compte** — Inscription locale avec nom, prénom, email, mot de passe
- **Connexion / Session** — Authentification persistante via SQLite
- **Synchronisation** — Préparé pour la sauvegarde cloud des favoris et mots de passe

### ℹ️ À Propos
- **Carte Hero premium** — Logo animé avec badge de version
- **Vision & Mission** — Description avec citation inspirante
- **Fonctionnalités** — Grille visuelle 2 colonnes avec 6 fonctionnalités clés
- **Piliers** — Rapide, Sécurisé, Intuitif
- **Badges de confiance** — Certifiée, Sécurisée, Made in République Centrafricaine

### 🆘 Aide
- **Écran d'aide dédié** — Guide d'utilisation intégré

---

## 🏗️ Architecture du Projet

```
lib/
├── main.dart                     # Point d'entrée
├── db_service.dart               # Service SQLite (7 tables)
├── screens/
│   ├── home_screen.dart          # Écran principal (recherche + WebView)
│   ├── settings_screen.dart      # Paramètres
│   ├── about_screen.dart         # À propos
│   ├── history_screen.dart       # Historique
│   ├── downloads_screen.dart     # Téléchargements
│   ├── tab_groups_screen.dart    # Groupes d'onglets
│   ├── group_details_screen.dart # Détails d'un groupe
│   ├── help_screen.dart          # Aide
│   ├── login_screen.dart         # Connexion
│   └── create_account_screen.dart# Inscription
├── widgets/
│   ├── search_bar_widget.dart    # Barre de recherche animée
│   ├── custom_back_button.dart   # Bouton retour réutilisable
│   ├── custom_app_bar.dart       # AppBar personnalisée
│   └── settings_tile.dart        # Tuile de paramètre
├── themes/
│   ├── app_theme.dart            # Thème de l'app
│   └── app_colors.dart           # Palette de couleurs
└── utils/
    └── design_constants.dart     # Espacements, rayons, durées d'animation
```

---

## 🗄️ Base de Données (SQLite)

| Table | Description |
|-------|------------|
| `users` | Comptes utilisateurs (nom, email, mot de passe) |
| `session` | Session active (connexion persistante) |
| `history` | Historique des recherches |
| `settings` | Paramètres clé/valeur (moteur, thème, position barre) |
| `tab_groups` | Groupes d'onglets |
| `tabs` | Onglets sauvegardés par groupe |
| `downloads` | Fichiers téléchargés |

---

## 📦 Dépendances

| Package | Utilisation |
|---------|------------|
| [`webview_flutter`](https://pub.dev/packages/webview_flutter) | Affichage des pages web |
| [`http`](https://pub.dev/packages/http) | Requêtes API (suggestions Google) |
| [`speech_to_text`](https://pub.dev/packages/speech_to_text) | Reconnaissance vocale |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | Gestion des permissions (micro) |
| [`sqflite`](https://pub.dev/packages/sqflite) | Base de données SQLite locale |
| [`path`](https://pub.dev/packages/path) | Manipulation des chemins de fichiers |
| [`path_provider`](https://pub.dev/packages/path_provider) | Accès aux répertoires système |

---

## 🚀 Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/votre-repo/djimsearch.git
cd djimsearch

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

---

## 📋 Configuration requise

| Plateforme | Prérequis |
|-----------|-----------|
| **Android** | SDK minimum 21 · Permissions : `INTERNET`, `RECORD_AUDIO` |
| **iOS** | Ajouter les permissions micro dans `Info.plist` (`NSSpeechRecognitionUsageDescription`, `NSMicrophoneUsageDescription`) |
| **Flutter** | SDK ≥ 3.9.2 |

---

## 📸 Captures d'écran

> *Espace réservé — Ajoutez vos captures ici*

| Accueil (Haut) | Accueil (Bas) | Résultats | Paramètres | À Propos |
|:-:|:-:|:-:|:-:|:-:|
| *screenshot* | *screenshot* | *screenshot* | *screenshot* | *screenshot* |

---

## 📄 Licence

Copyright © 2024–2026 **Panasoft Corporation** · Tous droits réservés.
