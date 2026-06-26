# Atelier 5 — Construire un script Bash d'inventaire (ShopEasy)

> **Objectif :** transformer les commandes manuelles d'inventaire en script réutilisable. \
> **Livrable attendu :** script `inventory.sh` fonctionnel, captures d'exécution et fichiers générés dans `exports/`.

---

## 1. Le script `scripts/inventory.sh`

Le script reprend les commandes des Ateliers 2 à 4 et y ajoute une **synthèse chiffrée** et des **contrôles d'exploitation**. Il est paramétrable (groupe de ressources en argument), robuste (`set -euo pipefail`, vérification préalable) et produit des exports **horodatés**.

```bash
#!/usr/bin/env bash
# =============================================================================
# inventory.sh - Inventaire d'exploitation de l'environnement ShopEasy (TP3)
# -----------------------------------------------------------------------------
# Produit un inventaire rejouable des ressources d'un groupe de ressources Azure :
#   - export JSON horodate des ressources (archivage / traitement programmatique) ;
#   - export TXT horodate de l'etat des VM ;
#   - synthese chiffree (total ressources, VM, comptes de stockage) ;
#   - controle de gouvernance (ressources sans tag Application) ;
#   - avertissement FinOps si des VM sont en cours d'execution.
#
# Usage : ./scripts/inventory.sh [resource-group]   (defaut : rg-shopeasy-dev)
# =============================================================================

set -euo pipefail

# --- Parametres --------------------------------------------------------------
RG="${1:-rg-shopeasy-dev}"          # groupe de ressources (argument ou defaut)
DATE="$(date +%Y%m%d-%H%M%S)"       # horodatage des fichiers d'export
OUT_DIR="exports"                   # repertoire de sortie
mkdir -p "$OUT_DIR"

echo "=============================================================="
echo " Inventaire Azure - groupe de ressources : $RG"
echo " Date : $DATE"
echo "=============================================================="

# --- 1. Verification de l'existence du groupe de ressources ------------------
if ! az group show --name "$RG" >/dev/null 2>&1; then
  echo "ERREUR : le groupe de ressources '$RG' est introuvable." >&2
  exit 1
fi

# --- 2. Export JSON des ressources -------------------------------------------
echo
echo "[1/4] Export des ressources -> $OUT_DIR/resources-$DATE.json"
az resource list --resource-group "$RG" \
  --query "[].{name:name,type:type,location:location,tags:tags,id:id}" \
  --output json > "$OUT_DIR/resources-$DATE.json"

# --- 3. Export TXT de l'etat des VM ------------------------------------------
echo "[2/4] Export de l'etat des VM -> $OUT_DIR/vms-$DATE.txt"
az vm list --resource-group "$RG" --show-details \
  --query "[].{name:name,powerState:powerState,publicIps:publicIps,vmSize:hardwareProfile.vmSize}" \
  --output table > "$OUT_DIR/vms-$DATE.txt"

# --- 4. Synthese chiffree ----------------------------------------------------
echo "[3/4] Calcul de la synthese..."
TOTAL=$(az resource list --resource-group "$RG" --query "length(@)" -o tsv)
NB_VM=$(az vm list --resource-group "$RG" --query "length(@)" -o tsv)
NB_STORAGE=$(az storage account list --resource-group "$RG" --query "length(@)" -o tsv)
NB_UNTAGGED=$(az resource list --resource-group "$RG" \
                --query "length([?tags.Application==null])" -o tsv)

echo
echo "--- Synthese ------------------------------------------------"
printf "  %-34s %s\n" "Ressources (total)"              "$TOTAL"
printf "  %-34s %s\n" "Machines virtuelles"             "$NB_VM"
printf "  %-34s %s\n" "Comptes de stockage"             "$NB_STORAGE"
printf "  %-34s %s\n" "Ressources sans tag Application" "$NB_UNTAGGED"
echo "-------------------------------------------------------------"

# --- 5. Controles et avertissements d'exploitation ---------------------------
echo "[4/4] Controles d'exploitation..."

# 5a. VM en cours d'execution : le compute est facture meme sans trafic
RUNNING=$(az vm list --resource-group "$RG" --show-details \
            --query "[?powerState=='VM running'].name" -o tsv)
if [[ -n "$RUNNING" ]]; then
  echo
  echo "  [AVERTISSEMENT] VM en cours d'execution (compute facture) :"
  echo "$RUNNING" | sed 's/^/    - /'
  echo "  -> envisager 'az vm deallocate' hors usage (cf. vm-power.sh)."
fi

# 5b. Ressources non conformes a la convention de tags d'exploitation
if [[ "$NB_UNTAGGED" -gt 0 ]]; then
  echo
  echo "  [INFO] $NB_UNTAGGED ressource(s) sans tag 'Application' :"
  az resource list --resource-group "$RG" \
    --query "[?tags.Application==null].name" -o tsv | sed 's/^/    - /'
fi

echo
echo "Inventaire termine. Fichiers generes dans $OUT_DIR/ :"
ls -1 "$OUT_DIR/resources-$DATE.json" "$OUT_DIR/vms-$DATE.txt" | sed 's/^/  /'
```

```bash
chmod +x scripts/inventory.sh
./scripts/inventory.sh rg-shopeasy-dev
```

---

## 2. Exécution réelle

```text
==============================================================
 Inventaire Azure - groupe de ressources : rg-shopeasy-dev
 Date : 20260626-103147
==============================================================

[1/4] Export des ressources -> exports/resources-20260626-103147.json
[2/4] Export de l'etat des VM -> exports/vms-20260626-103147.txt
[3/4] Calcul de la synthese...

--- Synthese ------------------------------------------------
  Ressources (total)                 13
  Machines virtuelles                2
  Comptes de stockage                1
  Ressources sans tag Application    11
-------------------------------------------------------------
[4/4] Controles d'exploitation...

  [AVERTISSEMENT] VM en cours d'execution (compute facture) :
    - vm-shopeasy-dev-web-1
  -> envisager 'az vm deallocate' hors usage (cf. vm-power.sh).

  [INFO] 11 ressource(s) sans tag 'Application' :
    - vnet-shopeasy-dev
    - shopeasydevdocs350wnq
    - pip-shopeasy-dev-web-1
    - pip-shopeasy-dev-lb
    - nsg-shopeasy-dev-web
    - pip-shopeasy-dev-web-2
    - lb-shopeasy-dev-web
    - nic-shopeasy-dev-web-2
    - nic-shopeasy-dev-web-1
    - vm-shopeasy-dev-web-1_OsDisk_1_...
    - vm-shopeasy-dev-web-2_OsDisk_1_...

Inventaire termine. Fichiers generes dans exports/ :
  exports/resources-20260626-103147.json
  exports/vms-20260626-103147.txt
```

> **Validation croisée :** l'avertissement ne liste **que** `vm-shopeasy-dev-web-1` (en `VM running`), et **pas** `vm-shopeasy-dev-web-2` (désallouée à l'Atelier 4). Le filtre `powerState=='VM running'` fonctionne donc correctement.

---

## 3. Fichiers générés

Export de l'état des VM (`exports/vms-20260626-103147.txt`) :

```text
Name                   PowerState      PublicIps       VmSize
---------------------  --------------  --------------  -----------------
vm-shopeasy-dev-web-1  VM running      20.240.233.166  Standard_B2ats_v2
vm-shopeasy-dev-web-2  VM deallocated  20.91.246.70    Standard_B2ats_v2
```

Extrait du JSON (`exports/resources-20260626-103147.json`, identifiant masqué) :

```json
{
  "id": "/subscriptions/<sub-id>/resourceGroups/rg-shopeasy-dev/providers/Microsoft.Network/virtualNetworks/vnet-shopeasy-dev",
  "location": "swedencentral",
  "name": "vnet-shopeasy-dev",
  "tags": { "cost_center": "cloud-training", "environment": "dev", "managed_by": "terraform", "owner": "formation", "project": "shopeasy" },
  "type": "Microsoft.Network/virtualNetworks"
}
```

---

## 4. Améliorations apportées (travail demandé)

| Amélioration demandée | Implémentation (JMESPath) | Résultat |
|---|---|---|
| Nombre total de ressources | `az resource list --query "length(@)"` | **13** |
| Nombre de VM | `az vm list --query "length(@)"` | **2** |
| Nombre de comptes de stockage | `az storage account list --query "length(@)"` | **1** |
| Ressources sans tag `Application` | `length([?tags.Application==null])` | **11** |
| Avertissement si VM `running` | `[?powerState=='VM running'].name` | `vm-shopeasy-dev-web-1` signalée |

---

## 5. Bonnes pratiques Bash appliquées

| Bonne pratique | Mise en œuvre |
|---|---|
| Arrêt sur erreur | `set -euo pipefail` (erreur, variable non définie, échec dans un pipe). |
| Paramétrage | `RG="${1:-rg-shopeasy-dev}"` : groupe en argument, valeur par défaut. |
| Vérification préalable | `az group show … || exit 1` : sortie propre si le RG n'existe pas. |
| Traçabilité | Exports **horodatés** (`-$DATE`) : pas d'écrasement, historique conservé. |
| Lisibilité | Étapes numérotées `[1/4]…[4/4]`, messages explicites, synthèse alignée. |
| Idempotence | `mkdir -p`, relances sans effet de bord (chaque exécution = nouveaux fichiers). |

---

## 6. Travail demandé — réponses

Toutes les améliorations demandées sont implémentées et vérifiées (§4) : compteurs (ressources, VM, stockage), détection des ressources sans tag `Application` (11 signalées), et avertissement FinOps sur les VM en cours d'exécution. Le script est **commenté, paramétrable, relançable** et produit des **exports horodatés** réutilisables dans le rapport d'exploitation.

> Les « captures d'exécution » attendues sont les sorties de terminal ci-dessus (§2-3), reproductibles par `./scripts/inventory.sh rg-shopeasy-dev`.

---

## ✅ État après l'Atelier 5

- Script `scripts/inventory.sh` fonctionnel, commenté, robuste et paramétrable.
- Synthèse automatisée : **13 ressources, 2 VM, 1 compte de stockage, 11 ressources sans tag `Application`**.
- Avertissement FinOps opérationnel (VM `running` détectée), filtrage d'état validé.
- Exports horodatés générés dans `exports/` (JSON ressources + TXT VM).

**Prêt pour l'Atelier 6 — Automatiser l'arrêt et le démarrage des VM.**
