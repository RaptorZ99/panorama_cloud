# TP1 — Architecture Cloud Azure pour ShopEasy

> **Bloc 4 — Optimisation du SI par l'apport du Cloud Computing** · Mastère Dev Manager Full Stack (RNCP 7) \
> **Cas fil rouge :** migration de l'application de gestion de commandes **ShopEasy** vers **Microsoft Azure**.
>
> **Binôme :** Louis SCARFONE & Maxence BOURRAGUE

Ce dépôt contient la conception, le déploiement (Azure CLI) et l'analyse d'une architecture cloud cible
pour ShopEasy, du diagnostic de l'existant jusqu'à la note de recommandations DSI.

---

## 📂 Structure

```
TP1/
├── README.md                            ← ce fichier
├── .env                                 ← identifiants/réfs (ignoré par git)
├── .gitignore
├── sujets/
│   ├── Cours_Magistral_TP1_Azure.pdf    ← support de cours
│   └── TP1_Architecture_Cloud_Azure.pdf ← énoncé du TP
└── livrables/
    ├── Atelier-01 … 15 .md              ← les 15 ateliers
    ├── Quiz.md                          ← quiz de validation
    └── assets/                          ← captures d'écran (.png)
```

---

## 📋 Livrables par atelier

| # | Atelier | Type | Livrable |
|---|---------|------|----------|
| 1 | Analyse de l'existant | Analyse | [Atelier-01](livrables/Atelier-01-Analyse-existant.md) |
| 2 | Choix des services Azure | Analyse | [Atelier-02](livrables/Atelier-02-Choix-services.md) |
| 3 | Architecture cible (schéma Mermaid) | Conception | [Atelier-03](livrables/Atelier-03-Architecture-cible.md) |
| 4 | Resource Group + nommage/tags | Pratique | [Atelier-04](livrables/Atelier-04-Preparation-environnement.md) |
| 5 | Réseau (VNet + subnets) | Pratique | [Atelier-05](livrables/Atelier-05-Reseau.md) |
| 6 | Filtrage réseau (NSG) | Pratique | [Atelier-06](livrables/Atelier-06-NSG.md) |
| 7 | Déploiement 2 VM web + Nginx | Pratique | [Atelier-07](livrables/Atelier-07-VM-web.md) |
| 8 | Répartiteur de charge | Pratique | [Atelier-08](livrables/Atelier-08-Load-Balancer.md) |
| 9 | Stockage documentaire (Blob) | Pratique | [Atelier-09](livrables/Atelier-09-Stockage.md) |
| 10 | Base managée (Azure SQL) | Pratique | [Atelier-10](livrables/Atelier-10-Base-SQL.md) |
| 11 | Supervision (Azure Monitor) | Pratique | [Atelier-11](livrables/Atelier-11-Supervision.md) |
| 12 | Estimation & optimisation (FinOps) | Analyse | [Atelier-12](livrables/Atelier-12-FinOps.md) |
| 13 | Analyse de disponibilité | Analyse | [Atelier-13](livrables/Atelier-13-Disponibilite.md) |
| 14 | Analyse de sécurité | Analyse | [Atelier-14](livrables/Atelier-14-Securite.md) |
| 15 | **Note de recommandations DSI** | Synthèse | [Atelier-15](livrables/Atelier-15-Note-DSI.md) |
| — | Quiz de validation | — | [Quiz](livrables/Quiz.md) |

---

## ⚙️ Environnement réel

- **Abonnement :** Azure for Students · **Région :** `swedencentral` (Stockholm).
- **Resource Group :** `rg-shopeasy-dev`.
- **Tailles VM :** `Standard_B2ats_v2` (alternative imposée à `B1s`, indisponible sur l'abonnement).

> **Contraintes Azure for Students rencontrées et résolues** (détaillées dans les ateliers 4/5/7) :
> régions restreintes par policy (France Central bloquée), tailles de VM limitées, déploiement zonal
> indisponible, providers `Microsoft.Compute/Storage/Sql` à enregistrer manuellement.

---

## 👀 Visualisation

- Les **schémas Mermaid** s'affichent nativement dans l'aperçu **VS Code** (extension *Markdown Preview
  Mermaid Support*) et sur **GitHub**.
- Les **captures d'écran** sont dans `livrables/assets/`.

---

## 🧹 Nettoyage de l'environnement

Pour supprimer toutes les ressources et **arrêter la facturation** (estimation ≈ 51,5 $/mois en 24/7) :

```bash
az group delete --name rg-shopeasy-dev --yes --no-wait
```

> ⚠️ Vérifier d'avoir récupéré toutes les captures avant suppression.
