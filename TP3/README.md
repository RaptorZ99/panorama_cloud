# TP3 — Administration & Automatisation Azure (ShopEasy)

> **Bloc 4 — Optimisation du SI par l'apport du Cloud Computing** · Mastère Dev Manager Full Stack (RNCP 7) \
> **Cas fil rouge :** exploiter et automatiser au quotidien l'environnement Azure de **ShopEasy**.
>
> **Binôme :** Louis SCARFONE & Maxence BOURRAGUE

Ce dépôt contient les livrables du TP3 : l'**exploitation** de l'architecture ShopEasy (conçue au TP1, industrialisée en Terraform au TP2). On passe du *déploiement* à l'*administration* : inventorier, taguer, administrer les VM, scripter (Bash + Python), superviser (Azure Monitor), sécuriser et optimiser les coûts (FinOps), puis produire un **rapport d'exploitation**.

> 📄 **Dossier de rendu PDF** : `latex/TP3-ShopEasy-Administration.pdf` *(généré via LaTeX — voir le dossier `latex/`)*.

---

## 📂 Structure

```
TP3/
├── README.md                              ← ce fichier
├── sujets/
│   ├── Cours_Magistral_TP3_Administration_Azure.pdf
│   └── TP3_Administration_Azure_CLI_Bash_Python.pdf   ← énoncé du TP
├── tp3-exploitation-azure/                ← mini-kit d'exploitation (exécutable)
│   ├── variables.sh                       ← variables centralisées (aucun secret)
│   ├── scripts/
│   │   ├── inventory.sh                    ← inventaire + synthèse
│   │   ├── vm-power.sh                     ← start/stop/deallocate/status (sécurisé)
│   │   └── healthcheck.sh                  ← contrôle de santé (code 0/1)
│   ├── python/
│   │   └── inventory.py                    ← inventaire SDK Azure → CSV
│   ├── exports/                            ← JSON, TSV, CSV, exports VM
│   └── logs/
│       └── vm-power.log                    ← journal des actions VM
└── livrables/
    ├── Atelier-01 … 11 .md                 ← les 12 ateliers (l'Atelier 12 = le rapport)
    ├── Rapport-exploitation-shopeasy.md    ← rapport d'exploitation (livrable final)
    ├── Quiz.md                             ← quiz de validation (20 questions)
    └── assets/                             ← captures d'écran (.png)
```

---

## 📋 Livrables par atelier

| # | Atelier | Livrable |
|---|---------|----------|
| 1 | Prise en main d'Azure CLI | [Atelier-01](livrables/Atelier-01-Prise-en-main-CLI.md) |
| 2 | Inventorier les ressources | [Atelier-02](livrables/Atelier-02-Inventaire.md) |
| 3 | Normaliser les tags d'exploitation | [Atelier-03](livrables/Atelier-03-Tags.md) |
| 4 | Administrer les machines virtuelles | [Atelier-04](livrables/Atelier-04-Administration-VM.md) |
| 5 | Script Bash d'inventaire (`inventory.sh`) | [Atelier-05](livrables/Atelier-05-Script-inventaire.md) |
| 6 | Arrêt/démarrage des VM (`vm-power.sh`) | [Atelier-06](livrables/Atelier-06-VM-power.md) |
| 7 | Exploiter un Storage Account | [Atelier-07](livrables/Atelier-07-Storage.md) |
| 8 | Surveiller les métriques (Azure Monitor) | [Atelier-08](livrables/Atelier-08-Monitoring.md) |
| 9 | Script de contrôle de santé (`healthcheck.sh`) | [Atelier-09](livrables/Atelier-09-Healthcheck.md) |
| 10 | Automatiser avec Python + Azure SDK | [Atelier-10](livrables/Atelier-10-Python-SDK.md) |
| 11 | Analyse FinOps d'exploitation | [Atelier-11](livrables/Atelier-11-FinOps.md) |
| 12 | **Rapport d'exploitation** (livrable final) | [Rapport](livrables/Rapport-exploitation-shopeasy.md) |
| — | Quiz de validation (20 questions) | [Quiz](livrables/Quiz.md) |

---

## ⚙️ Environnement réel

- **Abonnement :** Azure for Students · **Région :** `swedencentral` (Stockholm).
- **VM :** `Standard_B2ats_v2` (Ubuntu 22.04 + Nginx), 2 instances derrière un Load Balancer Standard.
- **Authentification :** session `az login` + `ARM_SUBSCRIPTION_ID`/`AZURE_SUBSCRIPTION_ID` (aucun identifiant en dur).
- **Environnement** redéployé depuis le code Terraform du TP2 (`terraform apply`) puis exploité en CLI/Bash/Python.

> **Contraintes Azure for Students** (héritées du TP1/TP2) : `francecentral` bloquée par policy → `swedencentral` ; `B1s` indisponible → `B2ats_v2`.

---

## ▶️ Utiliser le mini-kit d'exploitation

```bash
cd tp3-exploitation-azure
source variables.sh                       # variables + subscription (dynamique)

./scripts/inventory.sh rg-shopeasy-dev    # inventaire + synthèse + exports
./scripts/healthcheck.sh rg-shopeasy-dev  # contrôle de santé (code 0/1)
./scripts/vm-power.sh rg-shopeasy-dev status         # état des VM
./scripts/vm-power.sh rg-shopeasy-dev deallocate     # arrêt (avec confirmation)

# Inventaire Python → CSV (Excel/LibreOffice)
python3 -m venv .venv && source .venv/bin/activate
pip install azure-identity azure-mgmt-resource azure-mgmt-compute
export AZURE_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export AZURE_RESOURCE_GROUP="rg-shopeasy-dev"
python python/inventory.py                # génère exports/inventory.csv
```

> 🔒 **Sécurité** : aucun secret n'est versionné. Les identifiants (subscription/tenant) et l'IP admin sont **masqués** dans les livrables et captures. L'accès au Storage passe par RBAC (`--auth-mode login`).

---

## 🧹 Nettoyage (arrêt de la facturation)

L'environnement coûte **≈ 47 $/mois en 24/7** (Load Balancer ~39 %, compute ~30 %, IP publiques ~23 %). Pour réduire la facture :

```bash
./scripts/vm-power.sh rg-shopeasy-dev deallocate -y   # libère le compute des VM
```

Pour ramener le coût à **≈ 0**, détruire l'environnement depuis le projet Terraform du TP2 (`terraform destroy`) ; il reste recréable à l'identique par `terraform apply`.
