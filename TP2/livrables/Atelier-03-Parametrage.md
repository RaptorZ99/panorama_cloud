# Atelier 3 — Paramétrage du projet (ShopEasy)

> **Objectif :** rendre le projet réutilisable en externalisant les valeurs configurables et en
> centralisant le nommage et les tags. \
> **Livrable attendu :** `variables.tf` + `terraform.tfvars` + `locals.tf` (variables, valeurs d'environnement, locals et tags).

---

## 1. Variables d'entrée — `variables.tf`

```hcl
variable "project" {
  description = "Nom court du projet"
  type        = string
  default     = "shopeasy"
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Région Azure cible"
  type        = string
  default     = "francecentral"
}

variable "admin_username" {
  description = "Utilisateur administrateur Linux"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Chemin local vers la clé publique SSH"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorisé pour l'accès SSH"
  type        = string
}
```

| Variable | Type | Défaut | Rôle |
|---|---|---|---|
| `project` | string | `shopeasy` | Nom court du projet ; alimente le préfixe de nommage et les tags. |
| `environment` | string | `dev` | Environnement ; alimente le préfixe et les tags. |
| `location` | string | `francecentral` | Région Azure cible (surchargée par `terraform.tfvars`, cf. §2). |
| `admin_username` | string | `azureuser` | Compte administrateur Linux des VM. |
| `ssh_public_key_path` | string | *(requis)* | Chemin de la clé publique SSH injectée dans les VM. |
| `allowed_ssh_cidr` | string | *(requis)* | Plage CIDR autorisée à se connecter en SSH (IP de l'admin en `/32`). |

Les variables `ssh_public_key_path` et `allowed_ssh_cidr` sont **sans valeur par défaut** : elles sont
propres à l'environnement et doivent être fournies explicitement via `terraform.tfvars`. Externaliser ces
paramètres évite tout codage en dur et permet de réutiliser le même code pour d'autres environnements.

---

## 2. Valeurs de l'environnement — `terraform.tfvars`

### Adaptation de la région (Azure for Students)

Le TP fixe `location = "francecentral"`. Cette région est **bloquée** par la policy *Allowed resource
deployment regions* de l'abonnement *Azure for Students* (contrainte déjà rencontrée au TP1). La région
déployable retenue est **`swedencentral`**. La valeur est définie dans `terraform.tfvars` — chargé
automatiquement par Terraform — sans modifier le défaut déclaré dans `variables.tf`.

### Valeurs retenues (modèle anonymisé `terraform.tfvars.example`)

```hcl
project             = "shopeasy"
environment         = "dev"
location            = "swedencentral"      # francecentral bloquée sur Azure for Students
admin_username      = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
allowed_ssh_cidr    = "X.X.X.X/32"         # IP publique de l'administrateur (masquée)
```

Le fichier réel `terraform.tfvars` renseigne `allowed_ssh_cidr` avec l'**IP publique réelle** de
l'administrateur, en `/32`. Conformément à la règle « aucune valeur sensible dans un fichier versionné »,
`terraform.tfvars` est **exclu du dépôt** (`.gitignore`) ; seul `terraform.tfvars.example` ci-dessus,
**anonymisé**, est versionné pour documenter les variables attendues.

---

## 3. Locals et tags — `locals.tf`

```hcl
locals {
  # Préfixe de nommage commun à toutes les ressources : "shopeasy-dev"
  prefix = "${var.project}-${var.environment}"

  # Tags de gouvernance appliqués à chaque ressource
  common_tags = {
    project     = var.project
    environment = var.environment
    owner       = "formation"
    managed_by  = "terraform"
  }
}
```

- **`prefix`** vaut `shopeasy-dev`. Il est réutilisé pour nommer chaque ressource de façon cohérente
  (`rg-shopeasy-dev`, `vnet-shopeasy-dev`, `nsg-shopeasy-dev-web`…), ce qui évite de répéter la chaîne et
  garantit l'homogénéité du nommage.
- **`common_tags`** regroupe les tags de gouvernance appliqués à toutes les ressources :

| Tag | Valeur | Usage |
|---|---|---|
| `project` | `shopeasy` | Rattachement applicatif. |
| `environment` | `dev` | Distinction dev / test / prod. |
| `owner` | `formation` | Équipe responsable. |
| `managed_by` | `terraform` | Indique que la ressource est gérée en IaC (toute modification manuelle est une dérive). |

Centraliser le nommage et les tags dans `locals.tf` applique le principe *DRY* : une seule source de
vérité, modifiable en un point, propagée à l'ensemble des ressources.

---

## 4. Validation

```bash
terraform fmt
terraform validate
```

```text
(terraform fmt ne renvoie aucune sortie : fichiers déjà conformes)

Success! The configuration is valid.
```

Contrôle de la protection de l'IP par `.gitignore` :

```text
terraform.tfvars          -> IGNORE par git (OK, contient l'IP)
terraform.tfvars.example  -> VERSIONNE (OK, anonymise)
```

La configuration est valide et le fichier contenant l'IP réelle est bien exclu du dépôt.

---

## ✅ État du projet après l'Atelier 3

- `variables.tf` : 6 variables d'entrée (projet, environnement, région, admin, clé SSH, CIDR SSH).
- `terraform.tfvars` : valeurs de l'environnement `dev`, **région `swedencentral`** (adaptation Azure for Students), IP admin en `/32` — fichier **exclu du dépôt**.
- `terraform.tfvars.example` : modèle **anonymisé** versionné.
- `locals.tf` : préfixe de nommage `shopeasy-dev` + 4 tags de gouvernance communs.
- `terraform validate` : **Success! The configuration is valid.**

**Prêt pour l'Atelier 4 — création du groupe de ressources et du réseau (premier `terraform apply`).**
