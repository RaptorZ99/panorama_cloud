# TP2 — Infrastructure as Code avec Terraform sur Azure (ShopEasy)

> **Bloc 4 — Optimisation du SI par l'apport du Cloud Computing** · Mastère Dev Manager Full Stack (RNCP 7) \
> **Cas fil rouge :** industrialiser le déploiement Azure de **ShopEasy** avec **Terraform**.
>
> **Binôme :** Louis SCARFONE & Maxence BOURRAGUE

Ce dépôt contient le projet **Terraform** qui décrit, déploie et détruit de manière reproductible
l'architecture cible de ShopEasy conçue au TP1 : réseau segmenté, deux serveurs web derrière un load
balancer, stockage documentaire privé, le tout nommé, taggé, paramétré et supervisé par le code.

---

## 📂 Structure

```
TP2/
├── README.md                              ← ce fichier
├── sujets/
│   ├── Cours_Magistral_TP2_Terraform_Azure.pdf
│   └── TP2_Terraform_Azure.pdf            ← énoncé du TP
├── tp2-terraform-azure/                   ← projet Terraform (exécutable)
│   ├── versions.tf   providers.tf
│   ├── variables.tf  locals.tf  outputs.tf
│   ├── network.tf    security.tf
│   ├── compute.tf    loadbalancer.tf  storage.tf
│   ├── templates/cloud-init.yml
│   ├── terraform.tfvars.example          ← modèle (terraform.tfvars réel ignoré)
│   └── .gitignore
└── livrables/
    ├── Atelier-01 … 14 .md                ← les 14 ateliers
    ├── Note-technique.md                  ← synthèse des choix (livrable final)
    ├── Quiz.md                            ← quiz de validation
    └── assets/                            ← captures d'écran (.png)
```

---

## 📋 Livrables par atelier

| # | Atelier | Livrable |
|---|---------|----------|
| 1 | Initialisation du projet Terraform | [Atelier-01](livrables/Atelier-01-Initialisation-projet.md) |
| 2 | Déclaration des providers | [Atelier-02](livrables/Atelier-02-Providers.md) |
| 3 | Paramétrage (variables, tfvars, locals/tags) | [Atelier-03](livrables/Atelier-03-Parametrage.md) |
| 4 | Resource Group + réseau | [Atelier-04](livrables/Atelier-04-RG-Reseau.md) |
| 5 | Sécurisation réseau (NSG) | [Atelier-05](livrables/Atelier-05-NSG.md) |
| 6 | Deux VM Linux (cloud-init) | [Atelier-06](livrables/Atelier-06-VM-Linux.md) |
| 7 | Load Balancer | [Atelier-07](livrables/Atelier-07-Load-Balancer.md) |
| 8 | Storage Account (privé, versionné) | [Atelier-08](livrables/Atelier-08-Storage.md) |
| 9 | Outputs et validation | [Atelier-09](livrables/Atelier-09-Outputs.md) |
| 10 | Modification de l'infrastructure | [Atelier-10](livrables/Atelier-10-Modification.md) |
| 11 | Observation d'une dérive (drift) | [Atelier-11](livrables/Atelier-11-Drift.md) |
| 12 | Préparation d'un state distant | [Atelier-12](livrables/Atelier-12-State-distant.md) |
| 13 | Analyses coût / sécurité / maintenabilité | [Atelier-13](livrables/Atelier-13-Analyses.md) |
| 14 | Nettoyage de l'environnement | [Atelier-14](livrables/Atelier-14-Nettoyage.md) |
| — | **Note technique** (synthèse) | [Note-technique](livrables/Note-technique.md) |
| — | Quiz de validation | [Quiz](livrables/Quiz.md) |

---

## ⚙️ Environnement réel

- **Abonnement :** Azure for Students · **Région :** `swedencentral` (Stockholm).
- **Taille de VM :** `Standard_B2ats_v2` (alternative imposée à `B1s`, indisponible sur l'abonnement).
- **Authentification :** session `az login` + `ARM_SUBSCRIPTION_ID` (aucun identifiant en dur).

> **Contraintes Azure for Students** (héritées du TP1) : `francecentral` bloquée par policy → `swedencentral` ;
> `B1s` indisponible → `B2ats_v2`.

---

## ▶️ Déployer le projet

```bash
cd tp2-terraform-azure
cp terraform.tfvars.example terraform.tfvars     # renseigner allowed_ssh_cidr (IP admin /32)
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Sorties utiles après déploiement : `terraform output` (IP du Load Balancer, IP des VM, nom du Storage).

> 🔒 `terraform.tfvars` (IP admin) et `terraform.tfstate` (secrets en clair) sont **exclus du dépôt** par
> `.gitignore`. Les captures d'écran sont **anonymisées** (IP admin et identifiants Azure floutés).

---

## 🧹 Nettoyage (arrêt de la facturation)

```bash
terraform destroy
```

> Coût estimé ≈ **46,5 $/mois en 24/7** (postes principaux : Load Balancer, compute, IP publiques). La
> destruction du Resource Group ramène le coût à ≈ 0. Comme tout est décrit en code, l'environnement est
> recréable à l'identique par `terraform apply`.
