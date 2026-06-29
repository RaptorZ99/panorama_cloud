# TP4 — Monitoring, FinOps & Sécurité Azure (ShopEasy)

> **Bloc 4 — Optimisation du SI par l'apport du Cloud Computing** · Mastère Dev Manager Full Stack (RNCP 7) \
> **Cas fil rouge :** piloter l'exploitation de l'environnement Azure de **ShopEasy** — superviser, alerter, maîtriser les coûts, sécuriser et auditer.
>
> **Binôme :** Louis SCARFONE & Maxence BOURRAGUE

Ce dépôt contient les livrables du TP4 : la **mise en exploitation** de l'architecture ShopEasy (conçue au TP1, industrialisée en Terraform au TP2, administrée au TP3). On passe d'une logique de *construction* à une logique de *pilotage* : cadrer des indicateurs, mettre en place **Azure Monitor / Log Analytics**, créer des **alertes**, analyser les **coûts (FinOps)**, conduire une **revue de sécurité**, **auditer** les changements, puis produire une **note de recommandations DSI**.

> 📄 **Dossier de rendu à remettre** : [`latex/TP4-ShopEasy-Monitoring.pdf`](latex/TP4-ShopEasy-Monitoring.pdf)
> — **40 pages**, auto-contenu (les 9 ateliers, le quiz, toutes les commandes et toutes les captures).
> Source LaTeX : [`latex/TP4-ShopEasy-Monitoring.tex`](latex/TP4-ShopEasy-Monitoring.tex).

---

## 📂 Structure

```
TP4/
├── README.md                              ← ce fichier
├── sujets/
│   ├── Cours_Magistral_TP4_Monitoring_FinOps_Securite_Azure.pdf
│   └── TP4_MonitoringFinOpsSecurite_Azure.pdf   ← énoncé du TP
└── livrables/
    ├── Atelier-01 … 09 .md                ← les 9 ateliers
    ├── Quiz.md                            ← quiz de validation (20 questions)
    └── assets/                            ← captures d'écran (.png)
```

---

## 📋 Livrables par atelier

| # | Atelier | Livrable |
|---|---------|----------|
| 1 | Cadrer les indicateurs d'exploitation | [Atelier-01](livrables/Atelier-01-Indicateurs.md) |
| 2 | Préparer l'environnement Azure Monitor | [Atelier-02](livrables/Atelier-02-Azure-Monitor.md) |
| 3 | Superviser les machines virtuelles | [Atelier-03](livrables/Atelier-03-Supervision-VM.md) |
| 4 | Créer des alertes opérationnelles | [Atelier-04](livrables/Atelier-04-Alertes.md) |
| 5 | Construire un tableau de bord d'exploitation | [Atelier-05](livrables/Atelier-05-Dashboard.md) |
| 6 | Analyse FinOps | [Atelier-06](livrables/Atelier-06-FinOps.md) |
| 7 | Revue de sécurité Azure | [Atelier-07](livrables/Atelier-07-Securite.md) |
| 8 | Audit des changements et Activity Log | [Atelier-08](livrables/Atelier-08-Audit.md) |
| 9 | **Plan d'amélioration avant production** (note DSI) | [Atelier-09](livrables/Atelier-09-Note-DSI.md) |
| — | Quiz de validation (20 questions) | [Quiz](livrables/Quiz.md) |

---

## ⚙️ Environnement réel

- **Abonnement :** Azure for Students · **Région :** `swedencentral` (Stockholm).
- **Architecture :** 2 VM `Standard_B2ats_v2` (Ubuntu + Nginx) derrière un Load Balancer Standard, Storage privé, le tout redéployé depuis le **Terraform du TP2** (`terraform apply`, 21 ressources).
- **Supervision ajoutée au TP4 :** Log Analytics Workspace `law-shopeasy-dev`, diagnostic settings (Activity Log + Storage), 2 alertes + action group `ag-shopeasy-ops`.
- **Authentification :** session `az login` + `ARM_SUBSCRIPTION_ID`/`AZURE_SUBSCRIPTION_ID` (aucun identifiant en dur).

> **Contraintes Azure for Students** (héritées des TP1/2/3) : `francecentral` bloquée par policy → `swedencentral` ; `B1s` indisponible → `B2ats_v2`.

---

## ▶️ Rejouer les commandes (non requis au rendu)

```bash
# Préparer la supervision (Atelier 2)
az monitor log-analytics workspace create -g rg-shopeasy-dev --workspace-name law-shopeasy-dev --location swedencentral

# Alertes opérationnelles (Atelier 4)
az monitor action-group create -g rg-shopeasy-dev --name ag-shopeasy-ops --short-name shopops \
  --action email EquipeOps <email>
az monitor metrics alert create --name "alert-cpu-high-vm-shopeasy-dev-web-1" -g rg-shopeasy-dev \
  --scopes "$(az vm show -g rg-shopeasy-dev -n vm-shopeasy-dev-web-1 --query id -o tsv)" \
  --condition "avg Percentage CPU > 70" --window-size 5m --severity 2 --action ag-shopeasy-ops

# Revue de sécurité (Atelier 7) / Audit (Atelier 8)
az role assignment list -g rg-shopeasy-dev --include-inherited -o table
az network nsg rule list -g rg-shopeasy-dev --nsg-name nsg-shopeasy-dev-web -o table
az monitor activity-log list -g rg-shopeasy-dev --offset 8h --max-events 1000 -o table
```

> 🔒 **Sécurité** : aucun secret n'est versionné. Les identifiants (subscription/tenant) et l'IP admin sont **masqués** dans les livrables et **redactés (OCR)** dans les captures.

---

## 🧹 Nettoyage (arrêt de la facturation)

L'environnement coûte **≈ 47 $/mois en 24/7** (Load Balancer ~39 %, compute ~30 %, IP publiques ~23 %). Pour réduire la facture, désallouer les VM ; pour ramener le coût à **≈ 0**, détruire l'environnement depuis le projet Terraform du TP2 :

```bash
# 1) Supprimer les ressources créées HORS Terraform au TP4 (sinon elles bloquent la destruction du RG)
az monitor metrics alert delete   -g rg-shopeasy-dev -n alert-cpu-high-vm-shopeasy-dev-web-1
az monitor metrics alert delete   -g rg-shopeasy-dev -n alert-vm-unavailable-vm-shopeasy-dev-web-1
az monitor action-group delete    -g rg-shopeasy-dev -n ag-shopeasy-ops
az portal dashboard delete        -g rg-shopeasy-dev -n ShopEasy-Exploitation --yes
az monitor log-analytics workspace delete -g rg-shopeasy-dev -n law-shopeasy-dev --yes --force
az monitor diagnostic-settings subscription delete --name activitylog-to-law --yes

# 2) Détruire l'infrastructure (depuis TP2/tp2-terraform-azure)
terraform destroy
```

> ⚠️ Une ressource créée **hors Terraform** (alerte, workspace, diagnostic) dans le RG géré par Terraform peut **empêcher la destruction du groupe** : la supprimer avant `terraform destroy` (leçon du TP3).
