# Note technique — Infrastructure as Code ShopEasy (TP2)

> **Projet :** industrialisation du déploiement Azure de ShopEasy avec **Terraform**. \
> **Binôme :** Louis SCARFONE & Maxence BOURRAGUE — Mastère Dev Manager Full Stack, Bloc 4 (Cloud Computing). \
> **Objet :** synthèse des choix techniques, de sécurité, de coût et de gouvernance, et proposition d'évolution.

---

## 1. Contexte

Le TP1 avait **conçu et déployé manuellement** (Azure CLI) l'architecture cible de ShopEasy. Le TP2 reprend
cette architecture et la décrit en **Infrastructure as Code** : l'infrastructure devient un ensemble de
fichiers `.tf` **versionnés, relus, appliqués puis détruits** de manière reproductible et contrôlée. Le
résultat n'est pas seulement « une infrastructure qui fonctionne », mais une infrastructure **décrite
proprement, lisible, versionnable, sécurisée et maîtrisée dans son cycle de vie**.

---

## 2. Architecture déployée

| Couche | Ressources |
|---|---|
| **Organisation** | Resource Group `rg-shopeasy-dev` (région `swedencentral`), tags de gouvernance. |
| **Réseau** | VNet `10.20.0.0/16`, subnet `snet-web` `10.20.1.0/24`, NSG (HTTP ouvert, SSH restreint à l'IP admin). |
| **Calcul** | 2 VM Linux `Standard_B2ats_v2` (Ubuntu 22.04), Nginx installé par **cloud-init**, déployées via `count`. |
| **Répartition** | Load Balancer **Standard** (IP publique, backend pool des 2 VM, sonde HTTP, règle 80). |
| **Stockage** | Storage Account `StorageV2` **LRS**, container **privé** `documents`, **versioning** Blob activé. |
| **Exploitation** | Outputs (IP du LB, IP des VM, nom du Storage), state local protégé. |

**21 ressources** Terraform, déployées et validées (checklist technique de l'Atelier 9 : 11/11).

---

## 3. Choix techniques

| Choix | Décision | Justification |
|---|---|---|
| Outil IaC | **Terraform** + provider **`azurerm ~> 4.0`** | Déclaratif, multi-cloud, lisible ; provider standard Azure. |
| Authentification | Session **`az login`** + `ARM_SUBSCRIPTION_ID` (variable d'env) | Aucun identifiant en dur dans le code. |
| Région | **`swedencentral`** (au lieu de `francecentral`) | `francecentral` **bloquée** par la policy *Allowed regions* d'Azure for Students. |
| Taille de VM | **`Standard_B2ats_v2`** (au lieu de `B1s`) | `B1s` **indisponible** sur Azure for Students ; `B2ats_v2` recommandée par Microsoft. |
| Multiplication | **`count = 2`** pour IP/NIC/VM | Deux serveurs identiques sans duplication de code (DRY). |
| Provisionnement | **cloud-init** via `templatefile` + `custom_data` | Installation Nginx automatique, page personnalisée par serveur. |
| Clé SSH | `file(pathexpand(var.ssh_public_key_path))` | `file()` ne développe pas `~` → `pathexpand` requis. |
| Nommage / tags | `local.prefix` + `local.common_tags` | Source unique, cohérence et gouvernance (FinOps). |
| Lisibilité | Découpage par responsabilité (`network`, `security`, `compute`, `loadbalancer`, `storage`, `outputs`) | Projet relisible et maintenable. |

---

## 4. Sécurité

- **SSH restreint** à l'IP de l'administrateur (`/32`), jamais `0.0.0.0/0`.
- **Aucun secret dans le code** : `terraform.tfvars` (qui contient l'IP admin) est **exclu du dépôt** ; seul
  un `terraform.tfvars.example` anonymisé est versionné.
- **State protégé** : `terraform.tfstate` est `gitignore` — il contient des **données sensibles en clair**
  (constaté : `admin_password`, `primary_access_key`, `secret`).
- **Storage privé** : container `private`, **TLS 1.2** minimum, HTTPS-only.
- **Captures anonymisées** : IP admin et subscription/tenant IDs **floutés** sur les captures avant rendu.

**Recommandations pour la production** : Azure **Bastion** (suppression du SSH public), **backend de state
distant** chiffré + RBAC, `allow_nested_items_to_be_public = false` sur le Storage, **Application Gateway +
WAF** en frontal HTTPS, **Azure Policy** d'obligation de tags.

---

## 5. FinOps

Coût ≈ **46,5 $/mois en 24/7** (prix réels Azure Retail Prices, `swedencentral`). Postes principaux :
**Load Balancer (≈18 $)**, **compute des 2 VM (≈14 $)**, **IP publiques (≈11 $)** — le LB et les IP
facturent même à trafic nul. Leviers : **désallouer les VM** hors usage, **réduire les IP publiques**
(Bastion), **lifecycle policy** sur le Blob, et surtout **`terraform destroy`** entre les séances pour
ramener le coût à ≈ 0.

---

## 6. Gouvernance et cycle de vie

- **Workflow** : `init` → `fmt` → `validate` → `plan` → `apply` → `destroy`, le `plan` étant systématiquement
  relu avant application.
- **Modification maîtrisée** : l'ajout d'un tag se propage en **mise à jour en place** (`~`), sans recréation.
- **Dérive** : une modification manuelle (portail) est **détectée** par `terraform plan` et **réconciliée**,
  démontrant le rôle du code comme **source de vérité**.

---

## 7. Amélioration proposée (mise en autonomie — Option B : Azure Bastion)

**Objectif :** supprimer les IP publiques directes des VM et administrer via **Azure Bastion**, pour réduire
la surface d'attaque et le coût des IP.

**Modification envisagée :**
- ajout d'un subnet dédié **`AzureBastionSubnet`** (`10.20.255.0/27`) ;
- création d'un **`azurerm_bastion_host`** + son IP publique Standard ;
- **suppression des IP publiques des VM** (`azurerm_public_ip.web`) et du `public_ip_address_id` de la NIC ;
- adaptation du NSG : **suppression de la règle SSH publique** (l'accès passe par Bastion).

**Fichiers impactés :** `compute.tf` (NIC sans IP publique, retrait de `azurerm_public_ip.web`),
`network.tf` (subnet Bastion), `security.tf` (retrait de `Allow-SSH-Admin`), un nouveau `bastion.tf`, et
`variables.tf` (variable `enable_public_ip` pour basculer dev/prod).

**Risques / points d'attention :** le **Bastion a un coût horaire** non négligeable (à arbitrer pour un
environnement de dev), le test web direct par VM n'est plus possible (uniquement via le Load Balancer), et la
bascule nécessite un `plan` attentif (le retrait d'IP publiques entraîne une **mise à jour** des NIC, pas une
recréation des VM).

---

## 8. Conclusion

Le TP2 fait passer ShopEasy d'une infrastructure **créée à la main** à une infrastructure **décrite en code**,
reproductible et gouvernable. Les principes clés — **moindre privilège**, **pas de secret versionné**,
**nommage et tags cohérents**, **lecture systématique du plan**, **maîtrise du drift et des coûts** — sont
appliqués et documentés. Les évolutions proposées (Bastion, state distant, modularisation, CI/CD)
rapprocheraient l'environnement d'un usage de production.
