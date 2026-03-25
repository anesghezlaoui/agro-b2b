# AgroB2B (Flutter MVP)

Application B2B de commande orientée terrain (Algérie): supérettes, épiceries, mini-marchés, restaurants.

## Promesse

Commander rapidement, recevoir rapidement, sans erreur.

## Ce MVP contient

- Authentification simple:
  - inscription (nom, téléphone 10 chiffres, mot de passe)
  - connexion (téléphone + mot de passe)
  - état de validation admin
- Catalogue produits:
  - recherche
  - catégories (structure parent/enfant possible via `categoryPath`)
  - image, prix, stock, unité (`piece` / `carton`), variante
- Panier intelligent:
  - ajout, modification quantité, total
- Passer commande:
  - livraison ou retrait
- Historique:
  - liste commandes + bouton recommander
- Suivi simple:
  - en attente / en préparation / en livraison / livrée
- Profil:
  - infos client, crédit client (placeholder), déconnexion
- Accueil:
  - produits habituels + promotions

## Architecture

`provider` + séparation par features:

- `lib/features/auth`
- `lib/features/catalog`
- `lib/features/cart`
- `lib/features/orders`
- `lib/features/home`
- `lib/features/profile`

## API Django prévue

Endpoints déjà préparés dans `lib/core/constants/api_endpoints.dart`:

- `/api/login`
- `/api/register`
- `/api/produits`
- `/api/panier`
- `/api/commandes`

## Installation locale

1. Installer Flutter:
   - Linux (snap): `sudo snap install flutter --classic`
2. Dans ce dossier:
   - `flutter create .`
   - `flutter pub get`
   - Lancer **le backend Django** (voir `backend/README.md`) sur le port **8000**.
   - Lancer l’app (exemple **Chrome** — l’URL s’ouvre automatiquement dans le navigateur) :

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Où voir l’application (URL)

- **Chrome / Edge (recommandé)** : après `flutter run -d chrome`, une fenêtre navigateur s’ouvre. L’URL est du type `http://localhost:xxxxx` (affiche aussi dans le terminal au démarrage).
- **Linux desktop** : `flutter run -d linux` puis fenêtre native.
- **Émulateur Android** : utilise l’IP de ta machine, pas `127.0.0.1` :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### Message « Recompile complete. No client connected »

Cela signifie souvent qu’**aucun navigateur / appareil n’est connecté** au mode debug (onglet fermé, ou mode `web-server` sans ouverture manuelle de l’URL).

- Arrête (`q` dans le terminal) puis relance avec **`flutter run -d chrome`** et **laisse l’onglet ouvert**.
- Vérifie aussi la commande serveur : **`python manage.py runserver`** (avec un **espace** entre `python` et `manage.py`).

### Commandes visibles dans le backoffice

Une commande validée depuis l’app est envoyée en **`POST /api/commandes`** sur Django. Elle apparaît dans :

- **Gestion web** : `http://127.0.0.1:8000/gestion/commandes/` (compte staff / superuser)
- Le client doit être **validé** par le grossiste ; sinon l’API renvoie **403** et l’app affiche l’erreur (plus de fausse « commande locale »).

## Branchement ERP Django (étape suivante)

- Passer la vraie URL via `--dart-define=API_BASE_URL=...`
- Remplacer les providers mock par appels `ApiClient` (`GET/POST`)
- Gérer validation admin via endpoint backend
- Ajouter notifications push (Firebase ou autre)
- Ajouter vrai module admin (web recommandé: Django Admin/Backoffice dédié)
