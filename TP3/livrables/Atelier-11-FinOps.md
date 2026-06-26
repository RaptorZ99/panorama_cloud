# Atelier 11 — Analyse FinOps d'exploitation (ShopEasy)

> **Objectif :** identifier les actions simples permettant de limiter les coûts d'un environnement de développement. \
> **Livrable attendu :** tableau FinOps complété et trois recommandations courtes pour la DSI.

---

## 1. Ressources les plus coûteuses

Coûts calculés à partir des **prix réels** de l'API Azure Retail Prices (région `swedencentral`, USD, base 730 h/mois).

| Poste | Détail | Coût mensuel | Part |
|---|---|---|---|
| **Load Balancer Standard** | forfait règles + data | **≈ 18,25 $** | ~39 % |
| **Compute — 2 VM `B2ats_v2`** | 2 × 0,00972 $/h × 730 | **≈ 14,19 $** | ~30 % |
| **3 IP publiques Standard** | 3 × 0,005 $/h × 730 | **≈ 10,95 $** | ~23 % |
| 2 disques OS `Standard_LRS` | ~30 Go HDD | ≈ 2,60 $ | ~6 % |
| Storage Account LRS | usage faible | < 1 $ | ~2 % |
| **Total** | | **≈ 47 $/mois** | 100 % |

**Lecture :** les trois premiers postes (**Load Balancer + compute + IP publiques**) représentent **~92 %** du coût. Point décisif : le **Load Balancer** et les **IP publiques** sont facturés **24 h/24, indépendamment du trafic** ; seul le **compute** est réellement *élastique* (réductible par désallocation). En environnement de développement, la plus grande économie vient donc de **désallouer les VM** et de **détruire l'environnement entre les séances**.

> **Contrôle des ressources orphelines** (cf. cours) : `az disk list --query "[?managedBy==null]"` et `az network public-ip list --query "[?ipConfiguration==null]"` → **aucun disque orphelin, aucune IP non associée**. L'environnement est propre, sans coût « invisible ».

---

## 2. Tableau FinOps

| Action | Effet attendu | Risque / limite | Application à ShopEasy |
|---|---|---|---|
| **Désallouer les VM hors usage** | Réduction du coût compute | Indisponibilité de l'environnement | Via `vm-power.sh` : VM2 (HA) désallouée par défaut, VM1 arrêtée hors heures ouvrées. |
| **Réduire la taille des VM** | Réduction du coût mensuel | Performance plus faible | `B2ats_v2` déjà petite (burstable) ; surveiller `CPU Credits Remaining` avant tout downsize. |
| **Supprimer les disques inutilisés** | Réduction du stockage facturé | Risque de supprimer une donnée utile | **Aucun disque orphelin** actuellement ; contrôle à automatiser (intégré à `inventory.sh`). |
| **Standardiser les tags** | Meilleure analyse des coûts | Discipline d'équipe nécessaire | Tags normalisés (Atelier 3) à **étendre aux 11 ressources** encore en `snake_case`. |
| **Définir un budget** | Alerte en cas de dérive | Ne bloque pas la dépense | Budget mensuel 50 $ sur le RG, alertes à 80 % / 100 % (cf. §5). |

---

## 3. Stratégie d'arrêt/démarrage des VM de développement

- **Désallocation hors heures ouvrées** : `./scripts/vm-power.sh rg-shopeasy-dev deallocate` le soir, `start` le matin. Une VM utilisée ~50 h/semaine (au lieu de 168 h) **économise ~70 % de son compute** (≈ 14 $ → ≈ 4 $/mois pour les deux VM).
- **Automatisation** : planifier l'arrêt/démarrage via **Azure Automation runbook**, **Logic App** ou **cron** sur un poste d'administration ; alternativement, le tag **`AutoShutdown`** + Auto-shutdown natif des VM.
- **VM secondaire** : `vm-shopeasy-dev-web-2` (présente pour la haute disponibilité) reste **désallouée par défaut** en dev ; on ne la démarre que pour tester la répartition du Load Balancer.
- **Levier maximal** : entre deux séances, **détruire l'environnement** (`terraform destroy`, cf. TP2) ramène le coût à **≈ 0** ; il est recréable à l'identique par `terraform apply`.

---

## 4. Politique de tags FinOps

| Tag | Usage FinOps |
|---|---|
| `Application`, `Environment` | Ventiler la facture par application et par environnement. |
| `CostCenter` | Imputer les coûts à un centre de coût. |
| `Owner` | Identifier le responsable (validation des arrêts, contact incident). |
| `AutoShutdown` *(à ajouter)* | Piloter l'arrêt automatique (`true` en dev). |
| `Criticality` *(à ajouter)* | Prioriser ce qui ne doit pas être arrêté. |

**Mise en œuvre :** étendre la normalisation à **toutes** les ressources (les 11 restantes), puis imposer les tags obligatoires via **Azure Policy** (audit ou refus à la création d'une ressource sans `CostCenter`/`Owner`).

---

## 5. Seuil d'alerte budgétaire

L'environnement coûte **≈ 47 $/mois en 24/7**, ramené à **≈ 30 $** avec désallocation. On définit donc un **budget mensuel de 50 $** sur le groupe de ressources (marge raisonnable au-dessus de l'usage attendu), avec deux seuils d'alerte :

- **80 % (40 $)** — alerte de vigilance, notification à l'équipe CloudOps ;
- **100 % (50 $)** — alerte de dépassement, action requise.

```bash
# Exemple (Azure Cost Management)
az consumption budget create \
  --budget-name "budget-shopeasy-dev" --amount 50 --time-grain Monthly \
  --resource-group rg-shopeasy-dev
```

> Un budget **alerte mais ne bloque pas** la dépense : il doit être couplé à la discipline d'arrêt et à la revue régulière des coûts (Cost Management).

---

## 6. Trois recommandations FinOps pour la DSI

1. **Automatiser la désallocation des VM de développement** (arrêt hors heures ouvrées via `vm-power.sh` planifié, et destruction de l'environnement entre les séances) — **économie ~60-70 % du compute**, jusqu'à ≈ 0 hors usage.
2. **Supprimer les IP publiques directes des VM** et administrer via **Azure Bastion / `run-command`** — **≈ 7 $/mois économisés** et **surface d'attaque réduite** (gain FinOps *et* sécurité).
3. **Imposer les tags FinOps par Azure Policy et définir un budget mensuel (50 $) avec alertes 80 %/100 %** — gouvernance des coûts, imputation par centre de coût et détection précoce des dérives.

---

## 7. Travail demandé — réponses

**1. Ressources les plus coûteuses.** Load Balancer (~18 $), compute des 2 VM (~14 $), IP publiques (~11 $) = ~92 % (§1).
**2. Stratégie d'arrêt/démarrage.** Désallocation hors heures + VM2 éteinte par défaut + destruction entre séances (§3).
**3. Politique de tags FinOps.** Tags obligatoires étendus + `AutoShutdown`/`Criticality` + Azure Policy (§4).
**4. Seuil de budget.** 50 $/mois sur le RG, alertes 80 %/100 % (§5).
**5. Trois recommandations DSI.** Désallocation automatisée, suppression des IP publiques (Bastion), tags imposés + budget (§6).

---

## ✅ État après l'Atelier 11

- Coût réel chiffré (prix Azure Retail Prices) : **≈ 47 $/mois en 24/7**, dont ~92 % sur LB + compute + IP.
- Environnement **propre** : aucun disque orphelin, aucune IP non associée.
- Tableau FinOps complété (5 actions × effet × risque × application ShopEasy).
- Stratégie d'arrêt, politique de tags, seuil de budget (50 $) et **3 recommandations DSI** prêtes pour le rapport final.

**Prêt pour l'Atelier 12 — Rapport d'exploitation ShopEasy.**
