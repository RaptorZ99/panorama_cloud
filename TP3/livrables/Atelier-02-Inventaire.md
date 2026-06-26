# Atelier 2 — Inventorier les ressources Azure (ShopEasy)

> **Objectif :** produire un inventaire lisible des ressources ShopEasy, rejouable sans passer par le portail. \
> **Livrable attendu :** fichiers `exports/resources.json`, `exports/resources.tsv` et tableau d'inventaire complété.

---

## 1. Lister les ressources

L'inventaire est la base de l'exploitation : avant de surveiller, sécuriser ou optimiser, il faut savoir ce qui existe. Azure CLI permet de lister les ressources d'un groupe et de choisir le format de sortie selon l'usage (lecture humaine, traitement programmatique, extraction script).

```bash
source variables.sh

# Lecture humaine
az resource list --resource-group "$RG" --output table

# Colonnes utiles uniquement (JMESPath)
az resource list --resource-group "$RG" \
  --query "[].{Nom:name,Type:type,Region:location}" \
  --output table
```

```text
Nom                                                              Type                                     Region
---------------------------------------------------------------  ---------------------------------------  -------------
vnet-shopeasy-dev                                                Microsoft.Network/virtualNetworks        swedencentral
shopeasydevdocs350wnq                                            Microsoft.Storage/storageAccounts        swedencentral
pip-shopeasy-dev-web-1                                           Microsoft.Network/publicIPAddresses      swedencentral
pip-shopeasy-dev-lb                                              Microsoft.Network/publicIPAddresses      swedencentral
nsg-shopeasy-dev-web                                             Microsoft.Network/networkSecurityGroups  swedencentral
pip-shopeasy-dev-web-2                                           Microsoft.Network/publicIPAddresses      swedencentral
lb-shopeasy-dev-web                                              Microsoft.Network/loadBalancers          swedencentral
nic-shopeasy-dev-web-2                                           Microsoft.Network/networkInterfaces      swedencentral
nic-shopeasy-dev-web-1                                           Microsoft.Network/networkInterfaces      swedencentral
vm-shopeasy-dev-web-2                                            Microsoft.Compute/virtualMachines        swedencentral
vm-shopeasy-dev-web-1                                            Microsoft.Compute/virtualMachines        swedencentral
vm-shopeasy-dev-web-1_OsDisk_1_40bce1bcdd80471f889b4aed939adf2a  Microsoft.Compute/disks                  swedencentral
vm-shopeasy-dev-web-2_OsDisk_1_6fe73e0bfaa8402a8c3cb790c8a4cbce  Microsoft.Compute/disks                  swedencentral
```

---

## 2. Exporter l'inventaire (JSON + TSV)

Un inventaire d'exploitation doit être **conservé et rejouable**. On exporte donc deux formats : le **JSON** complet (traitement programmatique, archivage) et le **TSV** (réutilisation simple dans un tableur ou un script Bash).

```bash
mkdir -p exports

# Export JSON complet
az resource list --resource-group "$RG" --output json > exports/resources.json

# Export TSV (colonnes utiles)
az resource list --resource-group "$RG" \
  --query "[].{Nom:name,Type:type,Region:location}" \
  --output tsv > exports/resources.tsv
```

```console
$ wc -l exports/resources.json
     368 exports/resources.json
$ wc -l exports/resources.tsv
      13 exports/resources.tsv
```

Extrait d'une entrée du fichier `exports/resources.json` (identifiant d'abonnement masqué) :

```json
{
  "id": "/subscriptions/<sub-id>/resourceGroups/rg-shopeasy-dev/providers/Microsoft.Network/virtualNetworks/vnet-shopeasy-dev",
  "location": "swedencentral",
  "name": "vnet-shopeasy-dev",
  "tags": {
    "cost_center": "cloud-training",
    "environment": "dev",
    "managed_by": "terraform",
    "owner": "formation",
    "project": "shopeasy"
  },
  "type": "Microsoft.Network/virtualNetworks"
}
```

> On constate que les ressources portent déjà des **tags hérités du TP2** (appliqués par Terraform, en `snake_case`). L'Atelier 3 normalisera une stratégie de tags d'exploitation (`Application`, `Environment`, `Owner`, `CostCenter`, `ManagedBy`).

---

## 3. Identifier les types de ressources

```bash
az resource list --resource-group "$RG" --query "[].type" --output tsv | sort | uniq -c | sort -rn
```

```text
   3 Microsoft.Network/publicIPAddresses
   2 Microsoft.Network/networkInterfaces
   2 Microsoft.Compute/virtualMachines
   2 Microsoft.Compute/disks
   1 Microsoft.Storage/storageAccounts
   1 Microsoft.Network/virtualNetworks
   1 Microsoft.Network/networkSecurityGroups
   1 Microsoft.Network/loadBalancers
```

**8 types** de ressources pour **13 ressources** de premier niveau.

> `az resource list` ne renvoie que les ressources de **premier niveau**. Les sous-ressources (subnet, règles NSG, règle/sonde/backend pool du Load Balancer, associations NIC↔pool) sont **imbriquées** dans leur parent et n'apparaissent pas ici. Côté Terraform, l'état gère **21 objets** (13 ressources de premier niveau + sous-ressources + `random_string`).

---

## 4. Tableau d'inventaire

| Nom de la ressource | Type Azure | Région | Rôle dans l'architecture |
|---|---|---|---|
| `vnet-shopeasy-dev` | virtualNetworks | swedencentral | Réseau privé logique `10.20.0.0/16` ; segmentation (subnet `snet-web`). |
| `nsg-shopeasy-dev-web` | networkSecurityGroups | swedencentral | Pare-feu réseau du subnet web : HTTP (80) ouvert, SSH (22) restreint à l'IP admin. |
| `lb-shopeasy-dev-web` | loadBalancers | swedencentral | Load Balancer **Standard** L4 : répartit le trafic HTTP sur les 2 VM. |
| `pip-shopeasy-dev-lb` | publicIPAddresses | swedencentral | IP publique du Load Balancer = **point d'entrée HTTP unique** de ShopEasy. |
| `pip-shopeasy-dev-web-1` | publicIPAddresses | swedencentral | IP publique d'administration de la VM web 1. |
| `pip-shopeasy-dev-web-2` | publicIPAddresses | swedencentral | IP publique d'administration de la VM web 2. |
| `nic-shopeasy-dev-web-1` | networkInterfaces | swedencentral | Carte réseau de la VM web 1 (rattachée au subnet + backend pool). |
| `nic-shopeasy-dev-web-2` | networkInterfaces | swedencentral | Carte réseau de la VM web 2 (rattachée au subnet + backend pool). |
| `vm-shopeasy-dev-web-1` | virtualMachines | swedencentral | Serveur web 1 : Ubuntu 22.04 + Nginx (`Standard_B2ats_v2`). |
| `vm-shopeasy-dev-web-2` | virtualMachines | swedencentral | Serveur web 2 : Ubuntu 22.04 + Nginx (`Standard_B2ats_v2`). |
| `…web-1_OsDisk_…` | disks | swedencentral | Disque OS managé de la VM web 1. |
| `…web-2_OsDisk_…` | disks | swedencentral | Disque OS managé de la VM web 2. |
| `shopeasydevdocs350wnq` | storageAccounts | swedencentral | Stockage documentaire privé (`StorageV2`, LRS, versioning Blob). |

---

## 5. Travail demandé — réponses

**1. Créer un tableau d'inventaire (nom, type, région, rôle).**
Réalisé ci-dessus (§4) : 13 ressources de premier niveau, toutes en `swedencentral`, chacune reliée à son rôle dans l'architecture (réseau, sécurité, répartition de charge, calcul, stockage).

**2. Inventaire rejouable sans le portail.**
L'inventaire est produit **entièrement en CLI** et exporté en `exports/resources.json` (complet) et `exports/resources.tsv` (colonnes utiles). Les commandes sont reproductibles et seront industrialisées dans le script `inventory.sh` (Atelier 5).

**Lecture d'exploitation.** L'architecture est cohérente : un point d'entrée unique (Load Balancer + son IP), deux serveurs web identiques (haute disponibilité), un réseau segmenté protégé par un NSG, et un stockage privé. Les ressources sont **déjà taguées** (héritage Terraform) — la normalisation des tags d'exploitation fait l'objet de l'Atelier 3.

---

## ✅ État après l'Atelier 2

- Inventaire complet produit en CLI : **13 ressources**, **8 types**, région unique `swedencentral`.
- Exports générés : `exports/resources.json` (368 lignes) et `exports/resources.tsv` (13 lignes), rejouables et archivables.
- Tableau d'inventaire rôle par rôle établi (base du rapport d'exploitation).
- Constat : ressources déjà taguées (TP2), à normaliser à l'Atelier 3.

**Prêt pour l'Atelier 3 — Normaliser les tags d'exploitation.**
