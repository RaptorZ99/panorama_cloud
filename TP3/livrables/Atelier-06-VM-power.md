# Atelier 6 — Automatiser l'arrêt et le démarrage des VM (ShopEasy)

> **Objectif :** construire un script permettant de démarrer, arrêter ou désallouer les VM d'un environnement de développement, de manière sûre. \
> **Livrable attendu :** script `vm-power.sh`, journal d'exécution et explication des mesures de sécurité ajoutées.

---

## 1. Le script `scripts/vm-power.sh`

Le script pilote l'état d'alimentation de **toutes les VM** d'un groupe de ressources, avec trois garde-fous d'exploitation : refus des RG `prod`, confirmation avant action destructive, et journalisation horodatée.

```bash
#!/usr/bin/env bash
# =============================================================================
# vm-power.sh - Demarrage / arret / desallocation des VM d'un RG (ShopEasy TP3)
#   - refus d'agir sur un RG dont le nom contient "prod" ;
#   - confirmation utilisateur avant toute action destructive (stop/deallocate) ;
#   - journalisation horodatee de chaque action dans logs/vm-power.log.
#
# Usage : ./scripts/vm-power.sh <resource-group> <start|stop|deallocate|status> [-y]
# =============================================================================

set -euo pipefail

# --- Arguments ---------------------------------------------------------------
RG="${1:-}"
ACTION="${2:-}"
ASSUME_YES="${3:-}"          # -y / --yes : saute la confirmation (automatisation)

# --- Repertoire et fichier de log (relatifs au script) -----------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$(dirname "$SCRIPT_DIR")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/vm-power.log"

# --- Journalisation : horodate, console + fichier ----------------------------
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

# --- Validation des arguments ------------------------------------------------
if [[ -z "$RG" || -z "$ACTION" ]]; then
  echo "Usage: $0 <resource-group> <start|stop|deallocate|status> [-y]" >&2
  exit 1
fi

# --- Garde-fou 1 : interdiction d'agir sur un environnement de production -----
if [[ "$RG" == *prod* ]]; then
  log "REFUS : action '$ACTION' interdite sur un RG de production ('$RG')."
  exit 1
fi

# --- Verification de l'existence du groupe de ressources ---------------------
if ! az group show --name "$RG" >/dev/null 2>&1; then
  log "ERREUR : groupe de ressources '$RG' introuvable."
  exit 1
fi

# --- Garde-fou 2 : confirmation avant action destructive ---------------------
confirm() {
  if [[ "$ASSUME_YES" == "-y" || "$ASSUME_YES" == "--yes" ]]; then
    return 0
  fi
  local ANS=""
  read -r -p "Confirmer l'action '$ACTION' sur TOUTES les VM de '$RG' ? (oui/non) " ANS || true
  [[ "$ANS" == "oui" ]]
}

# --- Liste des VM du groupe --------------------------------------------------
VMS=$(az vm list --resource-group "$RG" --query "[].name" --output tsv)
if [[ -z "$VMS" ]]; then
  log "Aucune VM trouvee dans '$RG'."
  exit 0
fi

case "$ACTION" in
  stop|deallocate)
    if ! confirm; then
      log "Action '$ACTION' ANNULEE par l'utilisateur."
      exit 0
    fi
    ;;
esac

# --- Execution de l'action sur chaque VM -------------------------------------
log "=== Action '$ACTION' sur RG '$RG' ==="
for VM in $VMS; do
  case "$ACTION" in
    start)
      az vm start      --resource-group "$RG" --name "$VM" -o none
      log "  start      -> $VM : OK"
      ;;
    stop)
      az vm stop       --resource-group "$RG" --name "$VM" -o none
      log "  stop       -> $VM : OK (VM arretee, toujours allouee)"
      ;;
    deallocate)
      az vm deallocate --resource-group "$RG" --name "$VM" -o none
      log "  deallocate -> $VM : OK (compute libere)"
      ;;
    status)
      STATE=$(az vm get-instance-view --resource-group "$RG" --name "$VM" \
                --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
                --output tsv)
      log "  status     -> $VM : $STATE"
      ;;
    *)
      log "Action inconnue : '$ACTION' (attendu : start|stop|deallocate|status)"
      exit 1
      ;;
  esac
done
log "=== Termine ==="
```

---

## 2. Mesures de sécurité ajoutées

| Mesure | Mise en œuvre | Pourquoi |
|---|---|---|
| **Garde-fou production** | `if [[ "$RG" == *prod* ]]; then … exit 1` | Empêche tout arrêt accidentel d'un environnement de production. |
| **Confirmation destructive** | fonction `confirm()` sur `stop`/`deallocate` | Évite une coupure de service par erreur de frappe. |
| **Bypass contrôlé** | option `-y` / `--yes` | Permet l'automatisation (cron, CI) **en connaissance de cause**. |
| **Journalisation** | fonction `log()` → `logs/vm-power.log` (`tee`) | Traçabilité : qui a fait quoi, quand. Preuve d'audit. |
| **Actions sûres non bloquées** | `start` / `status` sans confirmation | Lecture et démarrage ne sont pas destructifs. |
| **Robustesse** | `set -euo pipefail`, vérification du RG, `Usage` | Arrêt propre en cas d'erreur ou de mauvais usage. |

---

## 3. Test de chaque action

**Actions sûres et garde-fous (instantanés) :**

```bash
./scripts/vm-power.sh rg-shopeasy-dev status               # lecture seule
./scripts/vm-power.sh rg-shopeasy-prod deallocate          # garde-fou prod
echo "non" | ./scripts/vm-power.sh rg-shopeasy-dev deallocate   # confirmation refusée
```

```text
2026-06-26 10:37:00 | === Action 'status' sur RG 'rg-shopeasy-dev' ===
2026-06-26 10:37:01 |   status     -> vm-shopeasy-dev-web-1 : VM running
2026-06-26 10:37:03 |   status     -> vm-shopeasy-dev-web-2 : VM deallocated
2026-06-26 10:37:03 | === Termine ===

2026-06-26 10:37:03 | REFUS : action 'deallocate' interdite sur un RG de production ('rg-shopeasy-prod').
(code retour : 1)

2026-06-26 10:37:05 | Action 'deallocate' ANNULEE par l'utilisateur.
```

**Actions destructives (avec confirmation / `-y`) :**

```bash
./scripts/vm-power.sh rg-shopeasy-dev start -y             # démarrage
echo "oui" | ./scripts/vm-power.sh rg-shopeasy-dev stop    # arrêt (confirmé)
./scripts/vm-power.sh rg-shopeasy-dev deallocate -y        # désallocation
```

```text
2026-06-26 10:37:32 | === Action 'start' sur RG 'rg-shopeasy-dev' ===
2026-06-26 10:37:35 |   start      -> vm-shopeasy-dev-web-1 : OK
2026-06-26 10:37:47 |   start      -> vm-shopeasy-dev-web-2 : OK

2026-06-26 10:37:49 | === Action 'stop' sur RG 'rg-shopeasy-dev' ===
WARNING: About to power off the specified VM...
It will continue to be billed. To deallocate a VM, run: az vm deallocate.
2026-06-26 10:38:23 |   stop       -> vm-shopeasy-dev-web-1 : OK (VM arretee, toujours allouee)
2026-06-26 10:38:56 |   stop       -> vm-shopeasy-dev-web-2 : OK (VM arretee, toujours allouee)

2026-06-26 10:39:14 | === Action 'deallocate' sur RG 'rg-shopeasy-dev' ===
2026-06-26 10:39:46 |   deallocate -> vm-shopeasy-dev-web-1 : OK (compute libere)
2026-06-26 10:40:20 |   deallocate -> vm-shopeasy-dev-web-2 : OK (compute libere)
```

> **Confirmation FinOps par Azure lui-même** : sur `stop`, Azure CLI affiche
> *« It will continue to be billed. To deallocate a VM, run: az vm deallocate. »*
> Cela confirme la distinction `stop` (facturé) / `deallocate` (compute libéré) du cours.

| Action | Garde-fou | Résultat observé |
|---|---|---|
| `status` | aucun (lecture seule) | `web-1: VM running`, `web-2: VM deallocated` |
| `deallocate` sur RG `*prod*` | garde-fou production | **REFUS** (code retour 1) |
| `deallocate` + réponse « non » | confirmation | **ANNULÉE** |
| `start -y` | aucun (non destructif) | 2 VM démarrées |
| `stop` + « oui » | confirmation acceptée | 2 VM arrêtées (toujours allouées) |
| `deallocate -y` | bypass automatisation | 2 VM désallouées (compute libéré) |

---

## 4. Journal d'exécution (`logs/vm-power.log`)

Chaque action est tracée, horodatée et conservée. Extrait du fichier (26 lignes) :

```text
2026-06-26 10:37:00 | === Action 'status' sur RG 'rg-shopeasy-dev' ===
2026-06-26 10:37:01 |   status     -> vm-shopeasy-dev-web-1 : VM running
2026-06-26 10:37:03 |   status     -> vm-shopeasy-dev-web-2 : VM deallocated
2026-06-26 10:37:03 | REFUS : action 'deallocate' interdite sur un RG de production ('rg-shopeasy-prod').
2026-06-26 10:37:05 | Action 'deallocate' ANNULEE par l'utilisateur.
2026-06-26 10:37:32 | === Action 'start' sur RG 'rg-shopeasy-dev' ===
2026-06-26 10:38:23 |   stop       -> vm-shopeasy-dev-web-1 : OK (VM arretee, toujours allouee)
2026-06-26 10:39:46 |   deallocate -> vm-shopeasy-dev-web-1 : OK (compute libere)
2026-06-26 10:41:18 |   status     -> vm-shopeasy-dev-web-1 : VM running
2026-06-26 10:41:19 |   status     -> vm-shopeasy-dev-web-2 : VM running
```

À l'issue des tests, l'environnement est remis à l'état nominal (les **2 VM `running`**) pour la suite du TP.

---

## 5. Travail demandé — réponses

**1. Tester chaque action du script.** `start`, `stop`, `deallocate`, `status` testées et journalisées (§3-4).
**2. Ajouter une confirmation avant `stop`/`deallocate`.** Fonction `confirm()` : la réponse « non » annule l'action ; bypass `-y` pour l'automatisation.
**3. Empêcher l'exécution sur un RG dont le nom contient `prod`.** `[[ "$RG" == *prod* ]]` → refus immédiat (code 1), tracé dans le journal.
**4. Ajouter une trace dans `logs/vm-power.log`.** Fonction `log()` (horodatage + `tee`) : chaque action est écrite sur la console **et** dans le fichier.

> Le livrable de cet atelier (script + journal + explications) est constitué des éléments ci-dessus ; aucune capture portail n'est requise.

---

## ✅ État après l'Atelier 6

- Script `scripts/vm-power.sh` fonctionnel : 4 actions (`start`/`stop`/`deallocate`/`status`).
- 3 mesures de sécurité opérationnelles : garde-fou `prod`, confirmation destructive (+ bypass `-y`), journalisation horodatée.
- Distinction `stop` / `deallocate` confirmée par l'avertissement natif d'Azure CLI.
- Journal `logs/vm-power.log` produit (26 lignes) ; environnement remis à l'état nominal (2 VM `running`).

**Prêt pour l'Atelier 7 — Exploiter un Storage Account.**
