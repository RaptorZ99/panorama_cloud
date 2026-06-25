# Atelier 13 — Analyse coût, sécurité et maintenabilité (ShopEasy)

> **Objectif :** analyser l'infrastructure déployée sous trois angles : coûts (FinOps), sécurité et maintenabilité. \
> **Livrable attendu :** tableau FinOps + tableau d'analyse de sécurité + réponses sur la maintenabilité.

---

## 1. Analyse FinOps

Prix unitaires **réels** (Azure Retail Prices API, région `swedencentral`, pay-as-you-go USD, hypothèse
24/7 = 730 h/mois) :

| Poste | Prix unitaire officiel | Source |
|---|---|---|
| VM `Standard_B2ats_v2` (Linux) | **0,00972 $/h** | Retail Prices (Basv2) |
| IP publique Standard (static) | **0,005 $/h** | Retail Prices |
| Disque OS Standard HDD **S4 (32 Go) LRS** | **1,536 $/mois** | Retail Prices |
| Load Balancer Standard | **≈ 0,025 $/h** (règles incluses) | tarif Standard (réf. TP1) |
| Blob Storage (faible volume) | négligeable | Retail Prices |

### Tableau FinOps

| Ressource | Coût relatif | Risque de surcoût | Optimisation proposée |
|---|---|---|---|
| **VM Linux** (2 × `B2ats_v2`) | **Moyen-élevé** — ≈ 14,2 $/mois | VM laissées allumées 24/7 sans usage réel | Désallouer hors période (`az vm deallocate`) ; **autoscale** en prod ; taille burstable adaptée |
| **IP publiques** (3) | **Moyen** — ≈ 10,9 $/mois | Facturées **même à trafic nul** ; multiplication inutile | Réduire à **1** (celle du LB) ; VM sans IP publique + **Bastion** |
| **Load Balancer** (Standard) | **Élevé** — ≈ 18,2 $/mois | Facturé en continu, même sans trafic | Garder pour la prod ; supprimer hors usage en dev ; **App Gateway** seulement si L7/WAF requis |
| **Storage Account** (LRS) | **Faible** — < 0,1 $/mois | Réplication **géo (GRS)** inutile en dev | **LRS** (pas GRS) ; suppression au nettoyage |
| **Versioning Blob** | **Faible → croissant** | Accumulation **illimitée** d'anciennes versions | **Lifecycle policy** : transition Cool/Archive + purge des versions > N jours |
| **Disques managés** (2 × OS, S4) | **Faible** — ≈ 3,1 $/mois | Disques **orphelins** après suppression VM ; surdimensionnement | Taille adaptée ; suppression au nettoyage ; Standard LRS |

> **Total indicatif ≈ 46,5 $/mois en 24/7.** Les **3 postes principaux** sont le **Load Balancer (18,2 $)**,
> le **compute des 2 VM (14,2 $)** et les **IP publiques (10,9 $)** — le LB et les IP facturent **même à
> trafic nul**. À l'inverse, **désallouer les VM** annule leur coût compute (≈ 14 $/mois économisés), et la
> **suppression du Resource Group** (Atelier 14) ramène le coût à **≈ 0**.

---

## 2. Analyse de sécurité

| Risque | Cause possible | Impact | Correction |
|---|---|---|---|
| **SSH trop ouvert** | Source `0.0.0.0/0` au lieu de l'IP admin | Scans automatisés, **brute-force**, compromission de VM | Restreindre à l'**IP `/32`** *(appliqué)* ; **Azure Bastion** / accès *just-in-time* en prod |
| **State exposé** | `tfstate` commité, ou Storage de state non protégé | **Fuite de secrets** (clés, mots de passe) + inventaire complet du SI | `.gitignore` *(appliqué)* ; **backend distant** chiffré + **RBAC** + restrictions réseau |
| **Storage public** | Container public ou `allowBlobPublicAccess = true` | **Fuite de documents métier** (non-conformité RGPD) | Container **privé** *(appliqué)* ; `allow_nested_items_to_be_public = false` |
| **Tags absents** | Oubli de tags sur certaines ressources | Coûts **non imputables**, gouvernance impossible | `common_tags` systématiques *(appliqué)* ; **Azure Policy** d'obligation de tags |
| **Secrets dans Git** | Mot de passe/clé en dur dans `.tf` ou `tfvars` versionné | **Compromission d'identifiants** | Aucun secret en dur ; `terraform.tfvars` **ignoré** *(appliqué)* ; **Key Vault** + variables CI sécurisées |
| **Modification manuelle** | Changement dans le portail hors Terraform | **Dérive**, imprévisibilité, sécurité affaiblie | Tout **par le code** (PR + `plan` + `apply`) ; `plan` régulier en CI ; **droits portail restreints** |

> Les corrections marquées *(appliqué)* sont déjà en place dans le projet (Ateliers 1, 5, 8, 11). Les autres
> sont les évolutions recommandées pour un passage en production.

---

## 3. Maintenabilité

**1. Comment rendre ce projet réutilisable pour un environnement de recette ?**
Le code est déjà **paramétré par variables** : il suffit de fournir un **`terraform.tfvars` par
environnement** (ex. `recette.tfvars` avec `environment = "recette"`, sa région, ses plages, sa taille de
VM) et un **state séparé** (clé/backend distincts, ex. `shopeasy/recette/terraform.tfstate`). Le **code reste
unique** ; seules les **valeurs** changent → on recrée un environnement de recette identique à la demande,
puis on le détruit. On peut aussi utiliser des **workspaces** Terraform.

**2. Quelles variables faudrait-il ajouter ?**
Pour gagner en flexibilité : `vm_size`, `vm_count` (nombre d'instances), `address_space` et
`web_subnet_prefix` (plans d'adressage par environnement), `storage_replication_type` (LRS/GRS selon
l'environnement), `enable_public_ip` (booléen pour **supprimer les IP publiques** des VM en prod), et un
bloc de **tags additionnels**. Cela évite tout codage en dur restant.

**3. Quels fichiers pourraient devenir des modules Terraform ?**
Le découpage actuel correspond déjà à des responsabilités modulaires :
- `network.tf` + `security.tf` → **module `network`** (RG, VNet, subnet, NSG) ;
- `compute.tf` → **module `compute`** (IP, NIC, VM, cloud-init) ;
- `loadbalancer.tf` → **module `loadbalancer`** ;
- `storage.tf` → **module `storage`**.

Ces modules, appelés depuis un `main.tf` avec des variables, deviennent **réutilisables** pour dev / recette
/ prod sans duplication de code.

**4. Quelles validations automatiques pourrait-on ajouter dans une pipeline CI/CD ?**
- `terraform fmt -check` et `terraform validate` (format + cohérence) ;
- **`tflint`** (bonnes pratiques) ;
- **`tfsec` / `checkov`** (analyse de sécurité statique de l'IaC) ;
- **`gitleaks`** (détection de secrets) ;
- **`terraform plan`** automatique sur chaque **pull request** + **revue de code** et **approbation** avant
  `apply` ;
- exécution **régulière de `plan`** pour détecter les **dérives** (drift).

---

## ✅ État après l'Atelier 13

- **FinOps** : coût ≈ **46,5 $/mois** en 24/7 (prix réels Azure Retail Prices), 3 postes principaux identifiés (LB, compute, IP), optimisations par ressource.
- **Sécurité** : 6 risques analysés (cause / impact / correction), dont 4 déjà corrigés dans le projet.
- **Maintenabilité** : réutilisation par environnement, variables à ajouter, modularisation, validations CI/CD.

**Prêt pour l'Atelier 14 — nettoyage de l'environnement (`terraform destroy`).**
