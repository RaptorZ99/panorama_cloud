# Atelier 9 — Écrire un script de contrôle de santé (ShopEasy)

> **Objectif :** créer un script qui vérifie rapidement si l'environnement est dans un état acceptable. \
> **Livrable attendu :** script `healthcheck.sh` final, preuve d'exécution et commentaires sur les vérifications ajoutées.

---

## 1. Le script `scripts/healthcheck.sh`

Le script enchaîne **8 contrôles** (les 4 de base + les 5 améliorations demandées) et renvoie un **code de sortie** exploitable par une automatisation (`0` = conforme, `1` = au moins un avertissement).

```bash
#!/usr/bin/env bash
# =============================================================================
# healthcheck.sh - Controle de sante de l'environnement ShopEasy (TP3)
#   Code de sortie : 0 si tout est OK, 1 si au moins un avertissement (WARN/KO).
#   Usage : ./scripts/healthcheck.sh [resource-group] [conteneur]
# =============================================================================

set -euo pipefail

RG="${1:-rg-shopeasy-dev}"
CONTAINER="${2:-operations}"
STATUS=0

ok()   { echo "  [OK]   $1"; }
warn() { echo "  [WARN] $1"; STATUS=1; }
ko()   { echo "  [KO]   $1"; STATUS=1; }

echo " Controle de sante Azure - $RG ($(date '+%Y-%m-%d %H:%M:%S'))"

# 1. Groupe de ressources (bloquant)
if az group show --name "$RG" >/dev/null 2>&1; then
  ok "groupe '$RG' present"
else
  ko "groupe '$RG' introuvable"; exit 1
fi

# 2. Machines virtuelles (au moins une) + etat
NB_VM=$(az vm list --resource-group "$RG" --query "length(@)" -o tsv)
if [[ "$NB_VM" -ge 1 ]]; then
  ok "$NB_VM VM(s) presente(s)"
  az vm list --resource-group "$RG" --show-details \
    --query "[].{name:name,state:powerState,ip:publicIps}" -o table | sed 's/^/       /'
else
  warn "aucune VM dans le groupe"
fi

# 3. Gouvernance : tag Owner sur le groupe
OWNER=$(az group show --name "$RG" --query "tags.Owner" -o tsv)
[[ -n "$OWNER" ]] && ok "tag Owner present ($OWNER)" || warn "tag Owner absent sur le groupe"

# 4. Gouvernance : ressources sans tag Application
UNTAGGED=$(az resource list --resource-group "$RG" --query "length([?tags.Application==null])" -o tsv)
[[ "$UNTAGGED" -eq 0 ]] && ok "toutes les ressources ont le tag Application" \
                        || warn "$UNTAGGED ressource(s) sans tag Application"

# 5. Supervision : alertes Azure Monitor
ALERTS=$(az monitor metrics alert list --resource-group "$RG" --query "length(@)" -o tsv)
[[ "$ALERTS" -ge 1 ]] && ok "$ALERTS alerte(s) configuree(s)" || warn "aucune alerte configuree"

# 6. Stockage : compte (recupere dynamiquement, robuste au suffixe aleatoire)
STORAGE=$(az storage account list --resource-group "$RG" --query "[0].name" -o tsv 2>/dev/null || true)
[[ -n "$STORAGE" ]] && ok "Storage Account present ($STORAGE)" || warn "aucun Storage Account"

# 7. Stockage : conteneur "operations"
if [[ -n "$STORAGE" ]] && \
   az storage container show --account-name "$STORAGE" --name "$CONTAINER" --auth-mode login >/dev/null 2>&1; then
  ok "conteneur '$CONTAINER' present"
else
  warn "conteneur '$CONTAINER' absent"
fi

# 8. Reseau : au moins une regle NSG autorisant HTTP/HTTPS
NB_HTTP=$(az network nsg list --resource-group "$RG" \
  --query "length([].securityRules[?direction=='Inbound' && access=='Allow' && (destinationPortRange=='80' || destinationPortRange=='443')][])" -o tsv)
[[ "$NB_HTTP" -ge 1 ]] && ok "$NB_HTTP regle(s) NSG autorisant HTTP/HTTPS" \
                       || warn "aucune regle NSG n'autorise HTTP/HTTPS (site inaccessible ?)"

# Bilan + code de sortie
[[ "$STATUS" -eq 0 ]] && echo " RESULTAT : OK - environnement conforme" \
                      || echo " RESULTAT : ATTENTION - points a verifier (voir [WARN])"
exit $STATUS
```

*(Le script versionné conserve l'affichage complet avec séparateurs ; la version ci-dessus est condensée pour la lisibilité du livrable.)*

---

## 2. Vérifications réalisées

| # | Contrôle | Origine | Niveau si échec |
|---|---|---|---|
| 1 | Groupe de ressources présent | base | **KO bloquant** (`exit 1`) |
| 2 | Au moins une VM (+ état) | **ajout** | WARN |
| 3 | Tag `Owner` sur le groupe | **ajout** | WARN |
| 4 | Ressources sans tag `Application` | base | WARN |
| 5 | Au moins une alerte Azure Monitor | base | WARN |
| 6 | Storage Account présent | **ajout** | WARN |
| 7 | Conteneur `operations` présent | **ajout** | WARN |
| 8 | Règle NSG autorisant HTTP/HTTPS | **ajout** | WARN |

---

## 3. Preuve d'exécution

```bash
chmod +x scripts/healthcheck.sh
./scripts/healthcheck.sh rg-shopeasy-dev
```

```text
==============================================================
 Controle de sante Azure - rg-shopeasy-dev
 2026-06-26 11:08:52
==============================================================
1. Groupe de ressources
  [OK]   groupe 'rg-shopeasy-dev' present
2. Machines virtuelles
  [OK]   2 VM(s) presente(s)
       Name                   State       Ip
       ---------------------  ----------  --------------
       vm-shopeasy-dev-web-1  VM running  20.240.233.166
       vm-shopeasy-dev-web-2  VM running  20.91.246.70
3. Gouvernance - tag Owner
  [OK]   tag Owner present (cloudops-shopeasy)
4. Gouvernance - tag Application
  [WARN] 11 ressource(s) sans tag Application
5. Supervision - alertes Azure Monitor
  [OK]   1 alerte(s) configuree(s)
6. Stockage - compte
  [OK]   Storage Account present (shopeasydevdocs350wnq)
7. Stockage - conteneur 'operations'
  [OK]   conteneur 'operations' present
8. Reseau - regle NSG HTTP/HTTPS
  [OK]   1 regle(s) NSG autorisant HTTP/HTTPS
==============================================================
 RESULTAT : ATTENTION - points a verifier (voir lignes [WARN])
==============================================================
>>> Code de sortie : 1
```

**Lecture :** 7 contrôles sur 8 sont au vert. Le seul avertissement — **11 ressources sans tag `Application`** — est cohérent avec l'Atelier 3 (la normalisation a porté sur le RG et les VM ; les ressources réseau/stockage gardent les tags techniques Terraform). Le script renvoie **code 1**, ce qui permet de l'intégrer dans une **CI/cron** : un code ≠ 0 déclenche une notification automatique.

---

## 4. Commentaires sur les vérifications ajoutées

- **Au moins une VM** — un groupe sans VM signifie l'absence du service web : c'est un signal d'alerte immédiat pour ShopEasy.
- **Tag `Owner`** — sans responsable identifié, impossible de savoir qui contacter en cas d'incident ni qui peut autoriser un arrêt ; c'est la base de la gouvernance.
- **Storage Account** — un environnement d'exploitation sans stockage ne peut pas **archiver ses rapports** ni ses exports (perte de traçabilité).
- **Conteneur `operations`** — vérifie que l'espace de dépôt des rapports existe réellement (un compte sans le bon conteneur casse la chaîne d'historisation).
- **Règle NSG HTTP/HTTPS** — sans règle d'ouverture sur 80/443, le site est **injoignable** depuis Internet ; ce contrôle confirme que le service est bien exposé (et, en miroir, sert de base à l'audit des ouvertures réseau).

> Le contrôle des tags `Application` est volontairement laissé en **WARN** : il reflète un vrai écart de gouvernance, à corriger via la généralisation des tags (recommandations FinOps, Atelier 11). Un healthcheck a justement pour rôle de **rendre visibles** ces écarts.

---

## 5. Travail demandé — réponses

Le script vérifie désormais : l'existence du **Storage Account** (6), du conteneur **`operations`** (7), d'**au moins une VM** (2), la présence d'un tag **`Owner`** (3) et d'**au moins une règle NSG** autorisant HTTP/HTTPS (8). Il est **commenté, robuste** (`set -euo pipefail`, RG récupéré/storage dynamique), et renvoie un **code de sortie** exploitable. La preuve d'exécution est fournie au §3.

---

## ✅ État après l'Atelier 9

- Script `scripts/healthcheck.sh` final : **8 contrôles** (4 de base + 5 ajouts), code de sortie 0/1.
- Exécution réelle : **7 OK / 1 WARN** (11 ressources sans tag `Application`), code 1 → intégrable en CI/cron.
- Contrôles de gouvernance, stockage et réseau ajoutés et commentés.
- Écart de tags rendu visible (à corriger via les recommandations FinOps).

**Prêt pour l'Atelier 10 — Automatiser avec Python et Azure SDK.**
