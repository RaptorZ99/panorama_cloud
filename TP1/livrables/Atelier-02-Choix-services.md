# Atelier 2 — Choix des services Azure (ShopEasy)

> **Objectif :** associer les besoins métier de ShopEasy aux services Azure pertinents. \
> **Livrable attendu :** un tableau besoins/services complété, avec justification technique et qualification IaaS / PaaS / gouvernance.

---

## 1. Tableau de choix besoins → services

| Besoin | Service Azure choisi | Justification technique | Modèle |
|---|---|---|---|
| **Hébergement de l'application** | **Azure Virtual Machines** (2 × VM Linux Ubuntu, Nginx/Apache) | Migration *lift-and-shift* de l'application PHP/Node.js existante **sans refonte** ; contrôle complet de l'OS et de la stack web ; deux instances pour préparer la redondance. *(Alternative cible : Azure App Service en PaaS.)* | **IaaS** |
| **Répartition de charge** | **Azure Load Balancer** (couche 4) | Distribue le trafic vers les 2 VM web et **retire automatiquement** une instance défaillante via sonde de santé → supprime le SPOF applicatif. *(Cible production : Application Gateway L7 avec TLS/WAF.)* | **IaaS / réseau** |
| **Base de données** | **Azure SQL Database** | Base **managée** : sauvegardes automatiques, patchs du moteur, haute disponibilité et chiffrement gérés par Azure ; remplace MySQL local ; **non exposée** à Internet. | **PaaS** |
| **Stockage des documents** | **Azure Storage Account** (Blob Storage) | Stockage objet **durable** pour les documents clients, avec **versioning** et politiques de cycle de vie ; sort les fichiers du serveur applicatif ; accès **privé**. | **PaaS** |
| **Isolation réseau** | **Azure Virtual Network** (+ subnets) | Réseau privé **isolé** ; segmentation en subnets (web / data / admin) → base de la sécurité réseau et de la séparation des couches. | **IaaS / réseau** |
| **Filtrage réseau** | **Network Security Groups (NSG)** | Filtrage **L3/L4** entrant/sortant par subnet ou interface ; n'ouvre que le nécessaire (80/443 web, 22 admin restreint à l'IP, 1433 data **depuis le subnet web uniquement**). | **IaaS / réseau (sécurité)** |
| **Gestion des accès** | **Microsoft Entra ID + Azure RBAC** | **Identités nominatives** + MFA ; attribution de rôles (Owner / Contributor / Reader) selon le **moindre privilège** → supprime le compte administrateur partagé. | **Gouvernance** |
| **Monitoring** | **Azure Monitor** | Collecte **métriques + logs**, **alertes actionnables** (CPU, disponibilité, échecs de connexion, coût) → visibilité opérationnelle et détection précoce des incidents. | **Gouvernance / observabilité** |
| **Suivi des coûts** | **Azure Cost Management** (+ tags) | Suivi des **coûts réels**, **budgets** et alertes, attribution par **tags** (application/environnement/propriétaire) → pilotage FinOps. | **Gouvernance** |

---

## 2. Question de justification — IaaS / PaaS / gouvernance et responsabilités

### Récapitulatif des qualifications

| Catégorie | Services concernés |
|---|---|
| **IaaS** (infrastructure) | Virtual Machines, Virtual Network, NSG, Load Balancer |
| **PaaS** (plateforme managée) | Azure SQL Database, Storage Account |
| **Gouvernance** (transverse) | Microsoft Entra ID + RBAC, Azure Monitor, Cost Management |

### En quoi cela modifie le niveau de responsabilité de l'équipe informatique

Le choix IaaS / PaaS / gouvernance déplace le curseur du **modèle de responsabilité partagée** :
plus un service est managé, plus Azure prend en charge de couches techniques, et plus l'équipe se
recentre sur la **valeur métier** (données, configuration, droits).

- **IaaS (VM, VNet, NSG, Load Balancer)** — Azure gère le matériel, l'hyperviseur et le réseau
  physique. **L'équipe reste responsable** de l'OS, des correctifs système, du durcissement, de la
  configuration réseau (subnets, règles NSG) et de la supervision système. → **Contrôle maximal,
  mais charge d'exploitation la plus élevée.**

- **PaaS (Azure SQL Database, Storage Account)** — Azure gère en plus l'OS, le moteur SQL/le service
  de stockage, les patchs, la haute disponibilité et les sauvegardes (selon configuration).
  **L'équipe se concentre** sur les données, le schéma, les droits applicatifs et le réseau d'accès.
  → **Administration fortement réduite**, responsabilité recentrée sur la donnée et la configuration.

- **Gouvernance (Entra ID/RBAC, Monitor, Cost Management)** — services transverses qui n'hébergent
  pas l'application mais **encadrent** identité, observabilité et coûts. Azure fournit l'outil ;
  **l'équipe définit les politiques** : rôles et moindre privilège, seuils d'alerte, budgets, tags.
  → Responsabilité de **pilotage et de conformité**, indépendante de l'hébergement.

### Lecture pour ShopEasy

En partant d'un existant **100 % à sa charge** (un serveur tout-en-un administré manuellement),
ShopEasy bascule vers un mix **IaaS + PaaS** qui :
- **transfère** à Azure l'administration de la base et du stockage (PaaS) ;
- **conserve** la maîtrise de la couche applicative le temps de la migration (IaaS) ;
- **ajoute** une couche de gouvernance (identités, supervision, coûts) qui n'existait pas.

> La suite logique (TP2) sera de réduire encore la part IaaS (App Service, Infrastructure as Code)
> une fois la migration stabilisée.
