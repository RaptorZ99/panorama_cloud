# Atelier 2 — Déclaration des providers (ShopEasy)

> **Objectif :** déclarer la version de Terraform et les providers requis, puis initialiser le projet. \
> **Livrable attendu :** `versions.tf` + `providers.tf` + le résultat de `terraform validate`.

---

## 1. `versions.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

| Élément | Signification |
|---|---|
| `required_version = ">= 1.6.0"` | Le projet exige Terraform 1.6 ou plus (version installée : 1.15.7). |
| `azurerm` (`hashicorp/azurerm`) | Provider standard pour Azure : RG, VNet, NSG, VM, Load Balancer, Storage. |
| `random` (`hashicorp/random`) | Génère un suffixe aléatoire pour rendre le nom du Storage Account globalement unique (Atelier 8). |
| `version = "~> 4.0"` | Opérateur pessimiste : autorise `>= 4.0.0` et `< 5.0.0` (toutes les `4.x`, pas la `5.0`). |
| `version = "~> 3.6"` | Autorise `>= 3.6.0` et `< 4.0.0`. |

L'opérateur `~>` fige la branche majeure d'un provider : les correctifs `4.x` sont récupérés
automatiquement, mais une version `5.0` (susceptible d'introduire des *breaking changes*) est exclue.

---

## 2. `providers.tf`

```hcl
provider "azurerm" {
  features {}
}
```

Le bloc `features {}` est obligatoire pour le provider `azurerm`, même vide : il active le comportement par
défaut du provider. L'authentification est héritée de la session Azure CLI (`az login`) déjà active, ce qui
évite d'inscrire un quelconque identifiant dans le code.

Le provider `azurerm` v4.x requiert un `subscription_id` lors des opérations `plan` et `apply` (pas pour
`init` ni `validate`). Il sera fourni via la variable d'environnement `ARM_SUBSCRIPTION_ID` à l'Atelier 4,
afin de conserver `providers.tf` minimal et sans identifiant en dur.

---

## 3. Initialisation — `terraform init`

```bash
terraform init
```

Sortie :

```text
Initializing provider plugins found in the configuration...
- Finding hashicorp/random versions matching "~> 3.6"...
- Finding hashicorp/azurerm versions matching "~> 4.0"...
- Installing hashicorp/random v3.9.0...
- Installed hashicorp/random v3.9.0 (signed by HashiCorp)
- Installing hashicorp/azurerm v4.78.0...
- Installed hashicorp/azurerm v4.78.0 (signed by HashiCorp)

Initializing the backend...

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```

`terraform init` a résolu et téléchargé les providers (vérifiés par signature HashiCorp) :
`azurerm v4.78.0` et `random v3.9.0`. La commande a créé le dossier de travail `.terraform/` (cache des
plugins) et le fichier `.terraform.lock.hcl` qui fige les versions exactes retenues.

---

## 4. Formatage — `terraform fmt`

```bash
terraform fmt
```

La commande ne renvoie aucune sortie : tous les fichiers `.tf` sont déjà conformes au style canonique HCL.
`terraform fmt` n'affiche que les fichiers qu'il modifie ; une sortie vide est le résultat attendu.

---

## 5. Validation — `terraform validate`

```bash
terraform validate
```

Sortie :

```text
Success! The configuration is valid.
```

La configuration est syntaxiquement et structurellement valide. `terraform validate` travaille en local :
il vérifie la cohérence du code sans contacter Azure ni l'existence réelle des ressources.

---

## ✅ État du projet après l'Atelier 2

- `versions.tf` : Terraform `>= 1.6.0`, providers **azurerm `~> 4.0`** et **random `~> 3.6`**.
- `providers.tf` : provider `azurerm` configuré (`features {}`), authentification héritée d'`az login`.
- `terraform init` réussi : providers **azurerm v4.78.0** et **random v3.9.0** installés, lock file créé.
- `terraform validate` : **Success! The configuration is valid.**

**Prêt pour l'Atelier 3 — paramétrage du projet (variables, `terraform.tfvars`, locals et tags).**
