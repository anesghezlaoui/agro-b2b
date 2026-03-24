# AgroB2B Backend (Django + DRF)

Backend API pour l'application Flutter AgroB2B.

## Setup rapide

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver 0.0.0.0:8000
```

## Comptes de demo

- Admin:
  - username: `admin`
  - password: `admin123`
- Client:
  - phone/login: `0550000000`
  - password: `test1234`

## Endpoints API

- `POST /api/register`
  - body: `{ "name": "Supérette A", "phone": "0551234567", "password": "secret123" }`
- `POST /api/login`
  - body: `{ "phone": "0551234567", "password": "secret123" }`
- `GET /api/produits` (token requis)
- `POST /api/panier` (token requis)
  - body: `{ "items": [{ "product_id": 1, "quantity": 2 }] }`
- `GET /api/commandes` (token requis)
- `POST /api/commandes` (token requis)
  - body: `{ "delivery_type": "livraison", "items": [{ "product_id": 1, "quantity": 2 }] }`
- `GET /api/notifications` (token requis)
- `POST /api/notifications/<id>/read` (token requis)
- `POST /api/clients/<id>/validate` (admin uniquement)

## Swagger / OpenAPI

- Schema OpenAPI: `GET /api/schema/`
- Swagger UI: `GET /api/docs/`

## Interface web grossiste (templates)

Espace d’administration dédié (HTML/CSS), réservé aux comptes **staff** ou **superuser** :

- Accueil du site : `http://127.0.0.1:8000/` (liens vers gestion, API, admin Django)
- Connexion : `http://127.0.0.1:8000/gestion/login/` (identifiants : ex. `admin` / `admin123` après `seed_demo`)
- **Première installation** (aucun superutilisateur) : la page d’accueil et la page de connexion proposent un lien vers  
  `http://127.0.0.1:8000/gestion/creer-superutilisateur/` pour créer le premier compte admin.
- Après connexion : `http://127.0.0.1:8000/gestion/`

Fonctions : **tableau de bord**, **clients** (validation, crédit, dette), **commandes & livraison** (statuts), **produits** (CRUD), **catégories** (CRUD, parent/enfant), **variantes** (liste globale + gestion par produit).

## Regle validation client

- Les endpoints metier (`produits`, `panier`, `commandes`, `notifications`) exigent un client valide.
- Si non valide, l'API retourne `403` avec `Compte non valide par le grossiste.`

## Notes Flutter

- Le token DRF doit etre envoye dans l'entete:
  - `Authorization: Token <token>`
- Base URL Flutter:
  - `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
