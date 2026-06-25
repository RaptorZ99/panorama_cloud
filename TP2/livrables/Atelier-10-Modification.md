# Atelier 10 — Modification de l'infrastructure (ShopEasy)

> **Objectif :** modifier l'infrastructure existante (ajout d'un tag) et lire le plan pour comprendre comment Terraform applique un changement. \
> **Livrable attendu :** modification de `locals.tf` + analyse du plan (mise à jour vs recréation).

---

## 1. Modification — ajout du tag `cost_center` dans `locals.tf`

```hcl
common_tags = {
  project     = var.project
  environment = var.environment
  owner       = "formation"
  managed_by  = "terraform"
  cost_center = "cloud-training"   # ← tag ajouté
}
```

Le tag `cost_center` est ajouté à `local.common_tags`. Comme ce *local* alimente l'attribut `tags` de toutes
les ressources concernées, **une seule modification** se propage à l'ensemble du projet (principe DRY).

---

## 2. Prévisualisation — `terraform plan`

```text
  # azurerm_lb.web will be updated in-place
  # azurerm_linux_virtual_machine.web[0] will be updated in-place
  # azurerm_linux_virtual_machine.web[1] will be updated in-place
  # azurerm_network_interface.web[0] will be updated in-place
  # azurerm_network_interface.web[1] will be updated in-place
  # azurerm_network_security_group.web will be updated in-place
  # azurerm_public_ip.lb will be updated in-place
  # azurerm_public_ip.web[0] will be updated in-place
  # azurerm_public_ip.web[1] will be updated in-place
  # azurerm_resource_group.main will be updated in-place
  # azurerm_storage_account.docs will be updated in-place
  # azurerm_virtual_network.main will be updated in-place

Plan: 0 to add, 12 to change, 0 to destroy.
```

Détail du changement sur le Resource Group (symbole `~` = mise à jour) :

```text
  # azurerm_resource_group.main will be updated in-place
  ~ resource "azurerm_resource_group" "main" {
        id   = ".../resourceGroups/rg-shopeasy-dev"
        name = "rg-shopeasy-dev"
      ~ tags = {
          + "cost_center" = "cloud-training"
            "environment" = "dev"
            "managed_by"  = "terraform"
            "owner"       = "formation"
            "project"     = "shopeasy"
        }
    }
```

Le `~` indique une **mise à jour en place** et le `+` l'**ajout** d'une seule clé de tag ; les autres tags
restent inchangés. Aucune ligne `-` (destruction) ni `-/+` (remplacement) n'apparaît.

---

## 3. Application — `terraform apply`

```text
azurerm_resource_group.main: Modifying...
azurerm_resource_group.main: Modifications complete after 1s
azurerm_public_ip.web[0]: Modifying...
azurerm_network_security_group.web: Modifications complete after 12s
azurerm_storage_account.docs: Modifications complete after 14s
azurerm_virtual_network.main: Modifications complete after 23s
azurerm_network_interface.web[0]: Modifications complete after 12s
azurerm_network_interface.web[1]: Modifications complete after 12s
...
Apply complete! Resources: 0 added, 12 changed, 0 destroyed.
```

Vérification de l'idempotence (un nouveau `plan` ne doit plus rien proposer) :

```text
Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

Vérification de la propagation du tag :

```bash
az group show -n rg-shopeasy-dev --query tags -o json
```

```json
{
  "cost_center": "cloud-training",
  "environment": "dev",
  "managed_by": "terraform",
  "owner": "formation",
  "project": "shopeasy"
}
```

```text
VNet  : cloud-training
VM-1  : cloud-training
LB    : cloud-training
Store : cloud-training
```

Le tag est présent sur l'ensemble des ressources taguées.

---

## 4. Analyse du plan

**1. Terraform prévoit-il de recréer toutes les ressources ?**
**Non.** Le plan annonce `0 to add, 12 to change, 0 to destroy` et chaque ressource est marquée
**`update in-place`** (`~`). Aucune ressource n'est détruite ni recréée : un tag est un attribut
**modifiable à chaud**, donc Terraform l'ajoute directement sur les ressources existantes, **sans
interruption de service**.

**2. Quelles ressources sont simplement mises à jour ?**
Les **12 ressources qui portent l'attribut `tags`** (= `local.common_tags`) : le Resource Group, le VNet, le
NSG, les 2 IP publiques web + l'IP du LB, les 2 NIC, les 2 VM, le Load Balancer et le Storage Account. Les
ressources **sans tags** (subnet, associations, backend pool, sonde, règle, container, `random_string`) ne
sont **pas concernées**.

**3. Pourquoi le plan est-il indispensable avant application ?**
Le plan montre **exactement** ce qui va changer **avant** d'agir. Ici, il confirme que seuls des tags sont
ajoutés **en place** (`~`), sans destruction (`-`) ni remplacement (`-/+`). Lire le plan permet de **détecter
une action dangereuse** (une destruction imprévue, un remplacement de VM qui effacerait des données locales)
**avant** qu'elle ne se produise. C'est le garde-fou du caractère **déclaratif** de Terraform : on valide
l'intention avant l'exécution.

---

## ✅ État de l'environnement après l'Atelier 10

- `locals.tf` modifié : ajout du tag `cost_center = "cloud-training"`.
- `terraform apply` : **12 ressources mises à jour en place**, 0 création, 0 destruction.
- Idempotence vérifiée (`plan` suivant : *no changes*), tag propagé à toutes les ressources taguées.
- Démonstration de la différence **mise à jour (`~`) vs recréation (`-/+`)**.

**Prêt pour l'Atelier 11 — observation d'une dérive (drift) Terraform.**
