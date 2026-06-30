# 🎓 Fiche de synthèse — Panorama du Cloud & Architecture Azure

> **Bloc 4 — Optimisation du SI par l'apport du Cloud Computing** · Mastère Dev Manager Full Stack (RNCP niv. 7)
> **Fil rouge :** migration de l'application **ShopEasy** (gestion de commandes) vers Microsoft Azure, à travers 4 TP.
> **Objet :** fiche théorique de révision couvrant **tous les concepts, principes et services** mis en œuvre dans les TP1 → TP4, pour préparer une évaluation écrite.

---

## 📑 Sommaire

0. [Vue d'ensemble du projet et des 4 TP](#0)
1. [Fondamentaux du Cloud Computing](#1)
2. [Modèles de service : IaaS, PaaS, SaaS](#2)
3. [Organisation et concepts de base d'Azure](#3)
4. [Le Well-Architected Framework](#4)
5. [Réseau Azure : VNet, subnets, NSG, équilibrage](#5)
6. [Calcul : machines virtuelles et alternatives managées](#6)
7. [Stockage Azure](#7)
8. [Bases de données managées](#8)
9. [Identité, droits et gouvernance](#9)
10. [Infrastructure as Code & Terraform (TP2)](#10)
11. [Administration & automatisation : CLI, Bash, Python (TP3)](#11)
12. [Monitoring & observabilité (TP3/TP4)](#12)
13. [FinOps : maîtrise des coûts](#13)
14. [Sécurité cloud (TP4)](#14)
15. [Audit, traçabilité & gouvernance avancée](#15)
16. [Disponibilité, résilience & analyse de risques](#16)
17. [Méthodologie : choix de services & note DSI](#17)
18. [Annexes : correspondance AWS/Azure, glossaire, Q/R type](#18)

---

<a name="0"></a>
## 0. Vue d'ensemble du projet et des 4 TP

### 0.1 Le fil rouge ShopEasy

**ShopEasy** est une PME qui exploite une application interne de gestion de commandes (consultation clients, saisie de commandes, génération de factures, dépôt de documents justificatifs). L'**existant** est un **serveur physique unique** dans les locaux :

- un serveur **Ubuntu** unique (mono-serveur) ;
- **Apache/Nginx** exposant l'application web ;
- application **PHP ou Node.js** installée localement ;
- base **MySQL** installée sur le **même serveur** ;
- **documents clients** dans un répertoire local ;
- **sauvegardes manuelles et irrégulières** ;
- **aucune supervision** centralisée ;
- un **compte administrateur partagé** par plusieurs personnes.

Le projet consiste à **migrer** cet existant vers Azure en adoptant une posture d'**architecte cloud junior** : analyser, concevoir, déployer, automatiser, administrer, superviser, sécuriser et optimiser.

### 0.2 Progression pédagogique des 4 TP

| TP | Thème | Logique | Outils clés | Livrables phares |
|---|---|---|---|---|
| **TP1** | Architecture cloud Azure | **Concevoir & déployer** manuellement | Portail / Azure CLI | Analyse de l'existant, architecture cible, note DSI |
| **TP2** | Infrastructure as Code | **Industrialiser** (rendre reproductible) | Terraform (HCL) | Projet `.tf`, note technique, drift |
| **TP3** | Administration & automatisation | **Exploiter** au quotidien | Azure CLI, Bash, Python (SDK) | Scripts (inventaire, vm-power, healthcheck), rapport d'exploitation |
| **TP4** | Monitoring, FinOps & sécurité | **Piloter & sécuriser** avant production | Azure Monitor, Cost Management, Defender | Indicateurs, alertes, dashboard, matrice de risques, note DSI |

> 🧭 **Fil conducteur :** TP1 *construit* l'architecture → TP2 la *décrit en code* → TP3 l'*administre* → TP4 la *supervise, optimise et sécurise*. On passe d'une logique de **construction** à une logique d'**exploitation** d'un système d'information.

### 0.3 Architecture cible ShopEasy (synthèse visuelle)

```
                         Internet / Utilisateurs
                                  │  HTTP/HTTPS (80/443)
                                  ▼
                  ┌───────────────────────────────┐
                  │   Azure Load Balancer (public) │  ← IP publique, sonde de santé
                  └───────────────┬───────────────┘
            Resource Group : rg-shopeasy-dev (région swedencentral)
   ┌──────────────────────── Virtual Network 10.x.0.0/16 ───────────────────────┐
   │  subnet snet-web (NSG nsg-web)        subnet snet-data (NSG nsg-data)        │
   │   ┌──────────┐   ┌──────────┐          ┌──────────────────┐  ┌───────────┐  │
   │   │ VM web-1 │   │ VM web-2 │ ───SQL──► │ Azure SQL Database│  │  Storage  │  │
   │   │ Nginx    │   │ Nginx    │ ──HTTPS─► │   (privée)        │  │  Account  │  │
   │   └──────────┘   └──────────┘          └──────────────────┘  │  (Blob)   │  │
   │   subnet snet-admin (Azure Bastion, optionnel)               └───────────┘  │
   └─────────────────────────────────────────────────────────────────────────────┘
   Plan transverse : Microsoft Entra ID + RBAC · Azure Monitor · Cost Management
```

> ⚠️ **Contraintes d'environnement *Azure for Students*** rencontrées dans les TP : région `francecentral` **bloquée** par policy → déploiement en **`swedencentral`** ; taille `Standard_B1s` **indisponible** → remplacée par **`Standard_B2ats_v2`** (burstable, recommandée par Microsoft) ; déploiement multi-zone indisponible ; providers à enregistrer manuellement. **À connaître : ces contraintes sont propres à l'abonnement étudiant, pas à Azure en général.**

---

<a name="1"></a>
## 1. Fondamentaux du Cloud Computing

### 1.1 Le SI traditionnel et ses limites

Dans une **architecture traditionnelle (on-premise)**, l'entreprise **achète ou loue des serveurs physiques**, les installe dans une salle informatique ou un datacenter, configure le réseau, installe les systèmes, gère les sauvegardes, applique les correctifs et anticipe la capacité. Ce modèle reste pertinent pour des contraintes fortes de **souveraineté**, de **latence locale** ou de **systèmes industriels**, mais présente des limites :

| Limite | Description |
|---|---|
| **Délai de mise à disposition** | Commander, recevoir, installer et configurer du matériel prend du temps. |
| **Surdimensionnement** | Il faut acheter de la capacité pour les pics, inutilisée le reste du temps. |
| **Coût initial (CAPEX)** | Investissements importants **avant** même de produire de la valeur. |
| **Maintenance opérationnelle** | Correctifs, remplacement matériel, sauvegardes, supervision, reprise sont à la charge de l'entreprise. |
| **Point de défaillance unique (SPOF)** | Une architecture mono-serveur concentre tous les risques. |

### 1.2 Définition du Cloud Computing

> 📌 **Cloud Computing :** modèle de **fourniture de ressources informatiques à la demande**, accessibles via le réseau, configurables rapidement, mesurables et **facturées selon l'usage** (ou selon une capacité réservée).

Le cloud propose des ressources (calcul, stockage, réseau, bases de données, sécurité, supervision, IA, services applicatifs) provisionnées via une **console**, une **API** ou un outil d'**Infrastructure as Code**. Le changement n'est pas que technique : le cloud transforme la **manière de piloter le SI** (tester rapidement, déployer automatiquement, mesurer finement les coûts, adapter la capacité à la demande).

### 1.3 Les 4 propriétés fondamentales du cloud

| Propriété | Définition | Implication |
|---|---|---|
| **Élasticité** | Capacité à **augmenter ou diminuer** les ressources selon le besoin (nombre de machines, taille des instances, capacités managées). | Absorber les pics (campagnes) sans surpayer le reste du temps. |
| **Facturation à l'usage** | Transformation des dépenses d'**investissement (CAPEX)** en dépenses **opérationnelles (OPEX)**. | Flexibilité, mais **risque** : une ressource oubliée continue de coûter → la maîtrise financière devient une compétence. |
| **Automatisation** | Les ressources se créent par console, API ou code (IaC). | Une architecture cloud ne se limite pas à des « clics » : elle doit être décrite, versionnée, reproductible. |
| **Services managés** | Le fournisseur prend en charge une partie de l'administration (ex. Azure SQL gère plateforme, HA, sauvegardes). | Transfère une partie de la responsabilité, sans la supprimer : elle se **transforme**. |

### 1.4 CAPEX vs OPEX

- **CAPEX** (*Capital Expenditure*) : dépense d'**investissement** (achat de matériel), capital immobilisé, modèle traditionnel.
- **OPEX** (*Operational Expenditure*) : dépense d'**exploitation** récurrente, payée à la consommation, modèle cloud.

> Le passage **CAPEX → OPEX** est un bénéfice majeur du cloud (pas d'avance de capital, paiement à l'usage), **mais** il déplace le risque vers la **dérive de coûts** : d'où l'importance du **FinOps** (§13).

---

<a name="2"></a>
## 2. Modèles de service : IaaS, PaaS, SaaS

Les modèles IaaS, PaaS et SaaS décrivent le **niveau d'abstraction** du service consommé : **plus le service est managé, plus le fournisseur prend en charge de responsabilités techniques** ; plus il est « bas niveau », plus le client conserve de **contrôle** mais aussi d'**administration**.

| Modèle | Description | Responsabilités principales du client | Exemples Azure |
|---|---|---|---|
| **IaaS** *(Infrastructure as a Service)* | Infrastructure à la demande : machines, disques, réseau. | OS, correctifs système, runtime, application, données, configuration de sécurité. | **Azure Virtual Machines**, **Azure Virtual Network**, Managed Disks |
| **PaaS** *(Platform as a Service)* | Plateforme managée pour déployer du code ou des données. | Code, configuration applicative, données, droits, paramétrage. | **Azure App Service**, **Azure SQL Database** |
| **SaaS** *(Software as a Service)* | Logiciel complet consommé comme un service. | Utilisateurs, données, configuration fonctionnelle. | **Microsoft 365**, **Dynamics 365** |

> 💡 **Message clé :** le choix IaaS/PaaS/SaaS est un **arbitrage** entre contrôle, responsabilité, rapidité de déploiement, compétences nécessaires, coût opérationnel et exigences de conformité.

**Application à ShopEasy :**
- Architecture **IaaS** (proche de l'existant) : VM pour l'app + base installée manuellement.
- Architecture **mixte** (retenue) : **VM** pour l'application (IaaS) + **Azure SQL Database** pour la base (PaaS) + **Storage Account** pour les fichiers (PaaS).
- Architecture **plus managée** (cible future) : **App Service** + Azure SQL + Storage.

> En partant d'un existant **100 % à sa charge**, ShopEasy bascule vers un **mix IaaS + PaaS** : Azure prend en charge la base et le stockage (PaaS), ShopEasy garde la maîtrise de la couche applicative (IaaS) le temps de la migration, et ajoute une **couche de gouvernance** (identités, supervision, coûts).

---

<a name="3"></a>
## 3. Organisation et concepts de base d'Azure

### 3.1 Les niveaux logiques d'Azure

| Concept | Rôle |
|---|---|
| **Tenant (Microsoft Entra ID)** | Représente l'**annuaire d'identité** de l'organisation : utilisateurs, groupes, applications, identités managées. |
| **Subscription (abonnement)** | Conteneur de **facturation et de gouvernance**. Les ressources sont créées dans une subscription. Porte les droits et les coûts. |
| **Resource Group (groupe de ressources)** | Conteneur **logique** regroupant les ressources d'une application, d'un environnement ou d'un projet. |
| **Resource (ressource)** | Service concret déployé : VM, VNet, Storage Account, Azure SQL Database, etc. |
| **Management Group** | Niveau au-dessus des subscriptions : organise plusieurs abonnements par domaine ou entité. |

> 📌 **Resource Group :** conteneur logique de ressources partageant un **cycle de vie commun**. Il sert à **administrer, sécuriser (RBAC), taguer, suivre les coûts et supprimer ensemble** un ensemble de ressources cohérent.

> ⚠️ **Erreur fréquente :** mélanger toutes les ressources dans un seul groupe. Un Resource Group doit traduire une **logique de cycle de vie** (application, environnement, projet, périmètre d'administration). Supprimer le RG supprime **toutes** les ressources qu'il contient.

### 3.2 Régions et Availability Zones

> 📌 **Région Azure :** zone **géographique** dans laquelle des services peuvent être déployés. Le choix d'une région influence la **latence**, les **coûts**, les **services disponibles**, les **contraintes réglementaires** (résidence des données) et les possibilités de **haute disponibilité**.

> 📌 **Availability Zone (zone de disponibilité) :** emplacement **physiquement séparé** au sein d'une région (alimentation, refroidissement et réseau **indépendants**). Déployer dans plusieurs zones réduit le risque d'indisponibilité lié à la panne d'un **datacenter**.

| | Région | Availability Zone |
|---|---|---|
| **Échelle** | Géographique (ex. France Central, Sweden Central) | Datacenter(s) au sein d'une région |
| **Sert à** | Latence, conformité, résidence des données | Résilience face à une panne locale |

> **Question type :** *Différence région / zone de disponibilité ?* → La **région** est une zone géographique ; la **zone de disponibilité** est un ensemble de datacenters physiquement séparés **au sein** d'une région, pour la résilience.

### 3.3 Conventions de nommage

Un nommage standardisé facilite la recherche, l'automatisation, l'audit et l'analyse des coûts. Convention type : `<type>-<application>-<environnement>[-région]`.

| Objet | Convention | Exemple |
|---|---|---|
| Resource Group | `rg-application-env` | `rg-shopeasy-dev` |
| Virtual Network | `vnet-application-env` | `vnet-shopeasy-dev` |
| Subnet | `snet-rôle` | `snet-web` |
| NSG | `nsg-rôle` | `nsg-web` |
| VM | `vm-rôle-num` | `vm-web-01` |
| Storage Account | nom **court, unique mondialement, minuscules, sans tiret** | `stshopeasyls01` |

> ⚠️ Les noms de **Storage Account** et de **serveur SQL** doivent être **uniques au niveau mondial** (d'où l'ajout d'un suffixe). Le Storage Account n'accepte ni tiret ni majuscule (3–24 caractères).

---

<a name="4"></a>
## 4. Le Well-Architected Framework

> 📌 **Azure Well-Architected Framework (WAF) :** cadre de réflexion permettant d'**évaluer et justifier une architecture** selon **5 piliers**. Il structure les arbitrages et les décisions.

| Pilier | Questions à se poser |
|---|---|
| **Reliability** (fiabilité) | Que se passe-t-il si une ressource tombe ? L'application continue-t-elle ? Existe-t-il sauvegarde et reprise ? |
| **Security** (sécurité) | Les accès sont-ils limités ? Les données protégées ? Les flux filtrés ? Les journaux permettent-ils un audit ? |
| **Cost Optimization** (coûts) | Les ressources sont-elles bien dimensionnées ? Les coûts suivis ? Les environnements inutiles arrêtés ? |
| **Operational Excellence** (exploitation) | L'exploitation est-elle standardisée ? Les changements traçables ? La supervision suffisante ? |
| **Performance Efficiency** (performance) | Les ressources répondent-elles aux besoins ? L'architecture absorbe-t-elle la croissance ? |

> 🧠 **À retenir :** une architecture cloud réussie **ne consiste pas à empiler des services**. Elle doit répondre à un **besoin métier**, **réduire les risques**, rester **exploitable** et conserver un **coût acceptable**. Critiquer une architecture, c'est identifier ses **points forts, ses risques, ses hypothèses et ses arbitrages** — pas la rejeter.

---

<a name="5"></a>
## 5. Réseau Azure : VNet, subnets, NSG, équilibrage

### 5.1 Virtual Network (VNet)

> 📌 **Azure Virtual Network (VNet) :** réseau **privé et isolé** dans Azure, comparable à un réseau local virtuel. Il permet aux ressources de communiquer entre elles, avec Internet ou avec un réseau d'entreprise. Il définit une **plage d'adresses IP privées** (ex. `10.10.0.0/16`) et contient des **subnets**.

- Les VNet utilisent des **plages privées RFC 1918** (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), **non routables sur Internet** → communications internes isolées, pas de conflit avec des adresses publiques.
- L'exposition vers l'extérieur est **explicite** (IP publique + Load Balancer), jamais par le VNet lui-même.

### 5.2 Subnets et segmentation réseau

> 📌 **Subnet (sous-réseau) :** subdivision d'un VNet permettant d'organiser les ressources **par fonction ou niveau d'exposition** (web, applicatif, données, administration).

**Pourquoi segmenter** (plutôt qu'un seul grand réseau « à plat ») :

| Raison | Explication |
|---|---|
| **Sécurité / cloisonnement** | On applique des **NSG différents** par couche → limite les **mouvements latéraux** (une VM web compromise ne joint pas directement la base). |
| **Moindre privilège réseau** | Chaque subnet n'autorise que les flux nécessaires (ex. SQL `1433` **uniquement depuis le subnet web**). |
| **Lisibilité / exploitation** | Découpage par fonction → réseau compréhensible, auditable, documentable. |
| **Gouvernance / évolutivité** | Route tables, Private Endpoints, bastion associables à un subnet précis ; plages réservées pour la croissance. |
| **Conformité** | Isoler les données sensibles dans une zone dédiée facilite le respect du **RGPD**. |

> Segmenter = appliquer la **défense en profondeur** au niveau réseau. La grande plage `/16` est l'espace global ; les `/24` matérialisent les **zones de confiance** distinctes.

> 💡 **Plan d'adressage (CIDR) :** Azure **réserve 5 adresses par subnet** (la 1ʳᵉ, les 3 suivantes, la dernière) → un `/24` (256 adresses) offre **251** adresses utilisables.

### 5.3 Network Security Group (NSG)

> 📌 **Network Security Group (NSG) :** ensemble de **règles de filtrage** du trafic réseau, associable à un **subnet** ou à une **interface réseau**. Chaque règle définit une **priorité**, une **source**, une **destination**, un **protocole**, un **port** et une **action** (autoriser/refuser).

**Caractéristiques :**
- Les règles sont évaluées par **ordre de priorité** (du plus petit nombre au plus grand) ; la première qui correspond s'applique.
- Le sens est filtré **séparément** : **Inbound** (trafic entrant) et **Outbound** (trafic sortant).
- Azure applique des **règles par défaut invisibles** :
  - *Inbound* : `AllowVnetInBound`, `AllowAzureLoadBalancerInBound`, puis **`DenyAllInBound`** (65500).
  - *Outbound* : `AllowVnetOutBound`, `AllowInternetOutBound`, puis `DenyAllOutBound`.
- Les règles personnalisées (priorité < 65000) sont évaluées **avant** ces défauts.

**Règles types pour ShopEasy :**

| Flux | Port | Source | Justification |
|---|---|---|---|
| HTTP | 80 | Internet (ou LB) | Accès à l'application web de test |
| HTTPS | 443 | Internet | Cible production (flux chiffrés) |
| SSH | 22 | **IP admin uniquement** | Administration Linux contrôlée |
| SQL | 1433 | **Subnet web uniquement** | Empêcher l'exposition directe de la base |

> ⚠️ **Erreur classique :** ouvrir SSH (22) à `0.0.0.0/0` (tout Internet) → exposition permanente aux **scans automatisés** et aux **attaques par force brute**. **Toujours** restreindre à l'IP admin, ou mieux : **Azure Bastion** + MFA + accès *just-in-time*.

> 💡 **Inbound vs Outbound :** par défaut Azure **autorise tout l'Outbound** et **restreint l'Inbound**. Restreindre aussi l'Outbound limite l'**exfiltration** et les communications malveillantes (rappel C2) depuis une VM compromise.

### 5.4 Équilibrage de charge et haute disponibilité

> 📌 **Load Balancer :** service qui **répartit le trafic** entrant sur plusieurs instances derrière un **point d'entrée unique** (une IP/DNS). Il améliore la **disponibilité** et permet de **monter en charge**.

> 📌 **Sonde de santé (health probe) :** vérifie en continu que chaque backend répond (ex. HTTP 200 sur `/`). Une instance défaillante est **automatiquement retirée** du pool ; elle est **réintégrée** dès qu'elle répond à nouveau. C'est la sonde qui rend la redondance **effective**.

**Azure Load Balancer vs Application Gateway :**

| Critère | **Azure Load Balancer** | **Application Gateway** |
|---|---|---|
| **Niveau OSI** | Couche **4** (TCP/UDP) | Couche **7** (HTTP/HTTPS) |
| **Comprend le contenu** | Non (répartition par *hash* 5-tuple) | Oui (URL, en-têtes, cookies) |
| **Fonctions** | Répartition réseau simple | Routage par chemin/hôte, **terminaison TLS**, affinité de session, **WAF** |
| **Complexité / coût** | Plus simple, moins cher | Plus riche, plus complexe |
| **Cas d'usage** | Première architecture web | Cible production (sécurité applicative, HTTPS, WAF) |

> 📌 **WAF (Web Application Firewall) :** pare-feu **applicatif** (couche 7) protégeant contre les attaques web (injections, XSS…). Disponible avec Application Gateway.

> 🧠 **La haute disponibilité ne vient pas d'un service isolé.** Elle résulte d'une **combinaison** : plusieurs instances, plusieurs **zones** si possible, sondes de santé, sauvegardes, supervision et procédures de reprise. Un Load Balancer **seul** ne rend pas une application hautement disponible.

### 5.5 Azure Bastion

> 📌 **Azure Bastion :** service permettant de se connecter en **SSH/RDP** à des VM **sans IP publique** ni port d'administration exposé, via le portail. Cible de production recommandée pour supprimer l'exposition directe du SSH (gain **sécurité** *et* **FinOps** — moins d'IP publiques).

---

<a name="6"></a>
## 6. Calcul : machines virtuelles et alternatives managées

### 6.1 Azure Virtual Machines (IaaS)

> 📌 **Azure Virtual Machine (VM) :** serveur **virtuel** où le client choisit l'image système, la taille, le disque, le réseau et la configuration. Modèle **IaaS** : contrôle complet de l'OS et de la stack, mais administration (patchs, durcissement, supervision système) à la charge du client.

**Dimensionnement** — tient compte de : CPU, mémoire, disque, trafic réseau, OS, contraintes applicatives et budget. Un mauvais dimensionnement entraîne soit une **mauvaise performance**, soit un **gaspillage financier**.

> 💡 **VM burstable (série B, ex. `Standard_B2ats_v2`) :** VM à **crédits CPU**. Au repos, elle accumule des crédits ; sous charge, elle les consomme pour « burster ». **Si le CPU reste élevé longtemps, les crédits s'épuisent et la VM est bridée (throttling)** → la métrique `CPU Credits Remaining` est à surveiller en plus du `Percentage CPU`. Adaptée au dev/test, à faible charge.

### 6.2 Cycle de vie d'une VM & `stop` vs `deallocate`

Une VM peut être : créée, démarrée, **arrêtée (stopped)**, **désallouée (deallocated)**, redémarrée, supprimée.

> ⚠️ **Point FinOps essentiel — `stop` ≠ `deallocate` :**
> - **Arrêt (stop)** : l'OS est arrêté mais la VM **reste allouée** sur l'hôte → le **compute continue d'être facturé**.
> - **Désallocation (deallocate)** : la VM est arrêtée **et** les ressources de calcul sont **libérées** (état *Stopped (deallocated)*) → le **compute n'est plus facturé**.
> Pour réduire les coûts d'un environnement de dev, il faut **désallouer**, pas seulement arrêter.

> 💡 Même **désallouée**, une VM continue de facturer son **disque OS managé** et son **IP publique statique** (réservée). Seul le **compute** est libéré.

### 6.3 VM vs App Service (PaaS)

> 📌 **Azure App Service :** plateforme **managée (PaaS)** pour héberger des applications web. Réduit les responsabilités liées à l'OS, aux patchs et à une partie de l'exploitation.

| Critère | Virtual Machines (IaaS) | App Service (PaaS) |
|---|---|---|
| **Contrôle système** | Élevé (OS, services, config) | Limité (plateforme managée) |
| **Administration** | Lourde (patchs, durcissement, supervision système) | Simplifiée (focalisation sur le code) |
| **Migration de l'existant** | Adaptée à une migration *lift-and-shift* | Peut demander une adaptation applicative |
| **Pédagogie** | Comprendre réseau & IaaS | Comprendre le PaaS |

### 6.4 cloud-init

> 📌 **cloud-init :** mécanisme de **provisionnement automatique au premier démarrage** d'une VM Linux (installation de paquets, écriture de fichiers, exécution de commandes). Transmis via `custom_data` (encodé en base64). Permet d'installer Nginx, publier une page, etc., **sans connexion SSH** — provisionnement reproductible.

---

<a name="7"></a>
## 7. Stockage Azure

### 7.1 Storage Account et types de stockage

> 📌 **Storage Account :** compte de stockage Azure pouvant héberger plusieurs types de données. Nom **unique mondialement**, minuscules, sans tiret.

| Service | Usage | Exemple ShopEasy |
|---|---|---|
| **Blob Storage** | Stockage **objet** pour fichiers non structurés | Factures PDF, images produits, exports, archives |
| **Managed Disks** | Disques attachés aux VM | Disque système d'une VM |
| **Azure Files** | Partage de fichiers SMB/NFS managé | Partage entre applications |
| **Tables / Queues** | Données clé-valeur / files d'attente | (selon besoin) |

> 📌 **Stockage objet (Blob) :** stockage de fichiers **non structurés** accessibles par API/SDK, **durable et redondé**, **découplé** des VM (les fichiers survivent à la destruction d'une VM), à la **scalabilité quasi illimitée** et au paiement à l'usage.

**Pourquoi le Blob plutôt qu'un disque local de VM ?** Durabilité/redondance gérées par Azure, découplage des VM, scalabilité, accès partagé par plusieurs instances, fonctions intégrées (versioning, soft-delete, cycle de vie, tags, journaux).

### 7.2 Niveaux d'accès (tiers) et cycle de vie

| Tier | Usage | Coût stockage | Coût d'accès |
|---|---|---|---|
| **Hot** | Données fréquemment consultées | Élevé | Faible |
| **Cool** | Données peu consultées (≥ 30 j) | Moyen | Moyen |
| **Archive** | Données très froides (≥ 90 j) | Très faible | Élevé (réhydratation) |

> 📌 **Lifecycle management policy :** règle automatisant la **transition** des blobs entre tiers (Hot → Cool → Archive) puis leur **suppression**, selon leur ancienneté. **Réduit les coûts** sans intervention manuelle. Ex. ShopEasy : Cool à 30 j, Archive à 90 j, suppression à 365 j sur le préfixe `archives/`.

### 7.3 Redondance

| Sigle | Signification | Portée |
|---|---|---|
| **LRS** | *Locally Redundant Storage* | Réplication **locale** (un datacenter) — suffisant en dev |
| **ZRS** | *Zone Redundant Storage* | Réplication sur **plusieurs zones** d'une région |
| **GRS** | *Geo Redundant Storage* | Réplication **géographique** (région secondaire) |

### 7.4 Sécurité du stockage

| Propriété | Apport |
|---|---|
| **Chiffrement au repos (SSE)** | Activé **par défaut** sur StorageV2 (clés gérées Microsoft) |
| **HTTPS-only + TLS 1.2 min** | Données chiffrées **en transit**, refus des protocoles obsolètes |
| **Accès public désactivé** (`allowBlobPublicAccess=false`) | Empêche qu'un conteneur soit rendu public **par erreur** (défense en profondeur) |
| **Versioning** | Conserve **chaque version** d'un blob → restauration après écrasement |
| **Soft-delete** | Récupération d'un blob/conteneur supprimé pendant N jours |
| **Conteneur privé** | Accès **authentifié uniquement** (clé, SAS à durée limitée, ou **RBAC**) |

> ⚠️ **Exposition des données :** rendre un stockage public « pour simplifier un test » est une erreur classique → **fuite de documents** clients (RGPD). En production, l'accès doit être **privé** ou strictement contrôlé. *(Test décisif : un accès anonyme à un blob d'un compte fermé renvoie `409 PublicAccessNotPermitted`.)*

---

<a name="8"></a>
## 8. Bases de données managées

### 8.1 Azure SQL Database (PaaS)

> 📌 **Azure SQL Database :** base de données SQL **managée** (PaaS). Azure prend en charge la maintenance de la plateforme, les **sauvegardes automatiques**, la **haute disponibilité** (selon configuration) et le chiffrement. Le client se concentre sur les **données, le schéma et les droits applicatifs**.

### 8.2 SQL sur VM (IaaS) vs Azure SQL Database (PaaS)

| Critère | Base sur VM (IaaS) | Azure SQL Database (PaaS) |
|---|---|---|
| **Administration OS** | À la charge du client (OS + moteur SQL) | **Aucune** (gérée par Azure) |
| **Sauvegardes** | À concevoir et opérer | **Automatiques** (*point-in-time restore*, PITR) |
| **Mises à jour** | À planifier | **Automatiques** |
| **Haute disponibilité** | À construire (cluster, réplication) | **Intégrée** selon le niveau (SLA jusqu'à 99,99 %) |
| **Sécurité** | Durcissement à la charge du client | **TDE par défaut**, pare-feu, Entra ID, audit, Defender for SQL |
| **Coût** | VM + licence SQL + disque + exploitation | Paiement du **service** (DTU/vCore) |
| **Flexibilité** | Contrôle total | Périmètre base, mais **scaling rapide** |

> 📌 **DTU vs vCore :** deux modèles d'achat d'Azure SQL. **DTU** (*Database Transaction Unit*) = mesure composite (CPU + mémoire + I/O) packagée par niveau (Basic, Standard, Premium). **vCore** = on choisit séparément le nombre de cœurs et la mémoire (plus flexible, transparent).

> 📌 **TDE (*Transparent Data Encryption*) :** chiffrement **au repos** de la base, activé par défaut sur Azure SQL.
> 📌 **PITR (*Point-In-Time Restore*) :** restauration de la base à un instant passé, grâce aux sauvegardes automatiques.
> 📌 **Failover group / géo-réplication :** mécanisme de **bascule** vers une réplique (autre région) pour la continuité d'activité.

### 8.3 Sécurité de la base

- **Ne jamais exposer la base directement à Internet.** Un serveur SQL ShopEasy est créé avec **pare-feu fermé** (0 règle = aucune IP autorisée).
- Pour un accès de test : ajouter **temporairement** une règle limitée à l'IP admin, **documentée et supprimée** après.
- **Cible production :** `publicNetworkAccess = Disabled` + **Private Endpoint** dans le subnet data → la base n'est joignable que depuis le réseau privé (subnet web), jamais depuis Internet.
- Appliquer le **moindre privilège** aux comptes applicatifs ; surveiller CPU, DTU/vCore, connexions, stockage, latence.

> 📌 **Private Endpoint :** interface réseau privée donnant accès à un service PaaS (SQL, Storage) **via une IP privée du VNet**, supprimant toute exposition publique.

---

<a name="9"></a>
## 9. Identité, droits et gouvernance

### 9.1 Microsoft Entra ID et RBAC

> 📌 **Microsoft Entra ID** (ex-Azure AD) : service d'**identité et d'authentification** d'Azure (utilisateurs, groupes, applications, identités managées).

> 📌 **Azure RBAC (*Role-Based Access Control*) :** modèle d'**attribution des droits par rôle**. On accorde un **rôle** à une **identité** sur un **scope** (étendue).

**Composants d'une attribution :** *qui* (utilisateur/groupe/identité) + *quel rôle* + *sur quel scope*.

**Scopes (du plus large au plus précis) :** Management Group → Subscription → Resource Group → Resource. Un droit accordé à un niveau est **hérité** par les niveaux inférieurs.

**Rôles intégrés courants :**

| Rôle | Usage |
|---|---|
| **Owner** | Administration complète **y compris la gestion des droits**. À **limiter fortement**. |
| **Contributor** | Gestion des ressources **sans** gestion des droits. À encadrer. |
| **Reader** | Consultation sans modification. Adapté à l'audit, au suivi. |
| **Cost Management Reader** | Consultation des coûts (FinOps). |

### 9.2 Principe du moindre privilège

> 📌 **Principe du moindre privilège :** un utilisateur, une application ou une identité technique ne doit disposer que des **permissions strictement nécessaires** à sa mission, **pendant la durée nécessaire**. Limite l'impact d'une erreur, d'un compte compromis ou d'une mauvaise manipulation.

> ⚠️ **Erreur de gouvernance :** donner le rôle **Owner** à toute une équipe « pour simplifier ». Le rôle `Contributor` (ou plus restreint) suffit souvent ; `Reader` pour la lecture seule. À compléter par le **MFA** et une **revue périodique** des rôles (voire **PIM** — *Privileged Identity Management*, élévation temporaire des droits).

### 9.3 Le compte administrateur partagé (anti-pattern)

Risques du compte admin partagé (existant ShopEasy) :
- **Perte de traçabilité / d'imputabilité** (impossible de savoir qui a fait quoi) → audit et conformité compromis ;
- **Non-respect du moindre privilège** (tous ont tous les droits) ;
- **Révocation difficile** (départ d'un collaborateur = changer le secret pour tous) ;
- **Surface d'attaque accrue** (secret partagé, pas de MFA individualisé).

→ **Correctif :** comptes **nominatifs** Entra ID + **RBAC** + **MFA**.

### 9.4 Tags et gouvernance

> 📌 **Tag :** métadonnée **clé=valeur** associée à une ressource, pour la **gouvernance** : attribution des coûts, identification du responsable, automatisation, filtrage.

**Tags recommandés :** `Application`, `Environment` (dev/test/prod), `Owner`, `CostCenter`, `Criticality` (low/medium/high), `ManagedBy`, `DataSensitivity`.

> 💡 **Snake_case vs PascalCase :** les tags posés par Terraform (TP2) étaient en `snake_case` (`cost_center`) ; l'exploitation (TP3) les a normalisés en `PascalCase` (`CostCenter`). Modifier des tags hors Terraform crée un **drift** (§10.9).

### 9.5 Azure Policy et niveaux de gouvernance

> 📌 **Azure Policy :** service permettant d'**imposer ou d'auditer** des règles de configuration (ex. refuser une ressource sans tag `Owner`, interdire une région, exiger le chiffrement). Encadre les écarts et la conformité.

| Niveau de gouvernance | Exemple |
|---|---|
| **Management Group** | Organiser plusieurs subscriptions par domaine/entité |
| **Subscription** | Isoler facturation, responsabilités, environnements |
| **Resource Group** | Regrouper les ressources d'une application/projet |
| **Tags** | Suivre coût, propriétaire, criticité, environnement |
| **Azure Policy** | Imposer/auditer des règles de configuration |
| **RBAC** | Contrôler les autorisations |

---

<a name="10"></a>
## 10. Infrastructure as Code & Terraform (TP2)

### 10.1 Le problème des infrastructures créées manuellement

Créer des ressources « au clic » dans le portail est utile pour découvrir, mais devient risqué dès qu'une équipe gère plusieurs environnements. Les manipulations manuelles :
- sont **difficiles à rejouer** exactement ;
- dépendent de la **mémoire** ou des notes de l'administrateur ;
- génèrent des **écarts entre environnements** ;
- compliquent les **revues de sécurité** et l'**estimation des coûts** ;
- rendent la **suppression** risquée.

> ⚠️ Deux environnements créés manuellement ne sont presque **jamais identiques** : une règle réseau oubliée, un tag absent ou une option non activée crée un incident difficile à diagnostiquer.

### 10.2 Définition de l'Infrastructure as Code (IaC)

> 📌 **Infrastructure as Code (IaC) :** gestion des ressources d'infrastructure au moyen de **fichiers texte** décrivant l'**état attendu** (réseaux, VM, bases, stockage, règles de sécurité, identités, politiques). Ces fichiers sont **versionnés (Git), relus en revue de code, testés et appliqués de façon répétable**.

> 🧠 L'IaC ne consiste **pas seulement** à automatiser la création d'une ressource. Elle rend l'infrastructure **explicite, versionnée, auditable, reproductible et gouvernable** : l'infrastructure devient un **actif logiciel**.

**Bénéfices pour l'entreprise :**

| Bénéfice | Explication |
|---|---|
| **Reproductibilité** | Une même config appliquée à plusieurs environnements. |
| **Traçabilité** | Changements suivis dans Git (auteur, date, justification, diff). |
| **Réduction des erreurs** | Actions manuelles répétitives remplacées par des fichiers contrôlés. |
| **Standardisation** | Modèles communs de réseau, sécurité, tags partagés par l'équipe. |
| **Vitesse de livraison** | Environnements créés vite et **détruits proprement**. |
| **Auditabilité** | Règles de sécurité et gouvernance **visibles dans le code**. |
| **Optimisation des coûts** | Ressources faciles à inventorier, taguer, ajuster, supprimer. |

### 10.3 Terraform : principes et positionnement

> 📌 **Terraform :** outil d'IaC **déclaratif**, **multi-cloud**, développé par **HashiCorp**. Il permet de **définir, prévisualiser et appliquer** des changements d'infrastructure. Configuration écrite en **HCL** (*HashiCorp Configuration Language*).

> 📌 **Déclaratif vs impératif :**
> - **Impératif** = décrire les **étapes à exécuter** (« crée un VNet, puis un subnet, puis attache un NSG »).
> - **Déclaratif** = décrire l'**état final attendu** (« l'infrastructure doit contenir ce VNet, ces subnets, ce NSG »). **Terraform calcule lui-même** les actions nécessaires. → C'est ce qui explique l'importance du **`plan`**.

**Multi-cloud :** le même outil pilote Azure, AWS, Google Cloud, Kubernetes, GitHub… via des **providers**.

### 10.4 Les providers Terraform

> 📌 **Provider :** plugin qui sait dialoguer avec l'**API** d'une plateforme et **traduit** les ressources Terraform en appels concrets.

| Provider Azure | Rôle |
|---|---|
| **azurerm** | Provider **standard** pour Azure Resource Manager (RG, VNet, NSG, VM, LB, Storage…). Choix prioritaire, lisible, documenté. |
| **azapi** | Plus proche des API ARM (fonctionnalités récentes/spécifiques). |
| **azuread** | Orienté identités Microsoft Entra ID. |
| **random** | Génère des valeurs aléatoires (ex. suffixe unique d'un Storage Account). |

> 💡 **Versionnage des providers** — opérateur pessimiste `~>` : `~> 4.0` autorise toutes les versions `4.x` mais **pas** la `5.0` (qui pourrait introduire des *breaking changes*).

### 10.5 Le workflow Terraform

> 📌 Cycle de vie d'un projet Terraform : **écrire → `init` → `fmt` → `validate` → `plan` → `apply` → (`destroy`)**.

| Commande (conceptuel) | Rôle |
|---|---|
| **`init`** | Initialise le projet : télécharge les **providers**, configure le **backend**, crée `.terraform/`. |
| **`fmt`** | **Formate** le code au style canonique HCL. |
| **`validate`** | Vérifie la **syntaxe et la cohérence** (en local, sans contacter Azure). |
| **`plan`** | **Prévisualise** les changements : compare l'état réel (connu via le *state*) à la config souhaitée. |
| **`apply`** | **Applique** les changements prévus. |
| **`destroy`** | **Supprime** les ressources gérées (utile pour arrêter la facturation entre séances). |

> 📌 **Symboles du plan** (à savoir lire) :
> - **`+`** : ressource à **créer** ;
> - **`-`** : ressource à **détruire** ;
> - **`~`** : ressource à **modifier en place** (*update in-place*) ;
> - **`-/+`** : ressource à **remplacer** (destruction **puis** recréation — ⚠️ peut entraîner une interruption ou une perte de données locales).

> 🧠 **Lire le `plan` avant l'`apply` est le garde-fou du modèle déclaratif.** Une **destruction** ou un **remplacement** imprévu (`-/+`) dans le plan est un **signal d'alerte**. Ex. : `-/+ azurerm_linux_virtual_machine.web` = la VM sera recréée.

### 10.6 Le langage HCL : variables, locals, outputs

Un bloc HCL suit la forme `resource "type" "nom_logique" { argument = "valeur" }`. Le **nom logique** est interne au projet (≠ nom Azure).

| Élément | Rôle | Métaphore |
|---|---|---|
| **Variable** *(d'entrée)* | Paramètre configurable du projet (projet, région, taille VM, CIDR SSH…). Évite le **codage en dur**. | Ce qui **entre** dans le projet |
| **Local** | Valeur **calculée** réutilisable (ex. préfixe de nommage, tags communs). Principe **DRY**. | Ce qui est **calculé** dans le projet |
| **Output** *(sortie)* | Information **exposée après déploiement** (IP du LB, nom du RG…), sans fouiller le portail. | Ce que le projet **expose** |

> 💡 **`terraform.tfvars`** porte les **valeurs concrètes** d'un environnement. Il ne doit **jamais** contenir de secret en clair ni d'IP réelle versionnée → on l'**exclut du dépôt** (`.gitignore`) et on versionne un `terraform.tfvars.example` **anonymisé**.

### 10.7 `count` et déploiement multiple

> 📌 **`count` :** méta-argument créant **plusieurs exemplaires** d'une ressource, indexés par `count.index` (0, 1…). Permet de déployer N instances identiques **sans dupliquer le code** (DRY). Ex. : `count = 2` pour les 2 VM web.

### 10.8 Le state Terraform

> 📌 **State (`terraform.tfstate`) :** fichier (JSON) qui établit le **lien entre les ressources déclarées dans le code et les ressources réellement créées** dans Azure. C'est la **source de vérité** de Terraform sur ce qu'il gère. Sans state, Terraform ne sait plus quelles ressources il pilote.

**Risques du state local :**
- **perte** du fichier (poste, disque) ;
- **conflits** entre administrateurs ;
- **absence de verrouillage** → corruption si `apply` simultanés ;
- **présence de secrets en clair** (mots de passe admin, clés d'accès Storage, chaînes de connexion) → un commit l'exposerait ;
- difficile à intégrer en **CI/CD**.

> ⚠️ Le state **contient des données sensibles en clair** (ex. attributs `admin_password`, `primary_access_key`, `secret`) **et** l'inventaire complet de l'infrastructure → ne **jamais** le publier dans un dépôt non sécurisé. Le `.gitignore` empêche sa publication mais ne résout ni le partage, ni le verrouillage.

> 📌 **Backend distant (state distant) :** stockage centralisé du state, sur Azure typiquement un **Storage Account + container Blob dédiés** (backend `azurerm`). Apporte : **partage** (équipe + CI/CD lisent le même state), **verrouillage** (un seul `apply` à la fois, via un *lease* sur le blob → pas de corruption), suppression du state des postes individuels. À **sécuriser** : RBAC, chiffrement, restrictions réseau, **clé séparée par environnement** (`shopeasy/dev/...`, `shopeasy/prod/...`) pour isoler dev/recette/prod.

### 10.9 Le drift (dérive)

> 📌 **Drift (dérive) :** écart entre l'**état réel** de l'infrastructure et l'**état décrit** dans le code Terraform. Se produit après une **modification manuelle** (portail) hors processus.

- Au prochain **`plan`**, Terraform **détecte l'écart** (en comparant le réel au code) et propose de **réaligner** sur le code (ex. supprimer un tag ajouté à la main).
- **Pourquoi c'est dangereux :** l'infrastructure devient **imprévisible**, la **sécurité s'affaiblit** (une règle ouverte à la main échappe à la revue), la **confiance dans le code** se perd, et un `apply` peut **annuler silencieusement** un correctif manuel.
- **Règle d'équipe :** tout changement passe **par le code** (modif `.tf` → **pull request** → revue → `plan` → `apply`). Le portail sert à **observer et diagnostiquer**, pas à modifier. Compléter par : `plan` régulier en CI (détection de drift), droits portail restreints, Azure Policy, formation.

### 10.10 Modules

> 📌 **Module Terraform :** ensemble **réutilisable** de configurations (ex. module `network`, `compute`, `storage`). Permet de factoriser une logique commune et de la réutiliser sur dev/recette/prod sans duplication. Un module doit être assez **générique** pour être réutilisable, sans être trop abstrait pour rester compréhensible.

### 10.11 Dépendances et graphe

Terraform construit automatiquement un **graphe de dépendances** à partir des **références entre ressources** (ex. un VNet qui utilise `azurerm_resource_group.rg.name` dépend du RG → le RG est créé en premier). La plupart du temps les **dépendances implicites** suffisent ; `depends_on` ne sert que lorsque la dépendance n'est pas visible dans les attributs.

> ⚠️ Un usage **excessif de `depends_on`** masque souvent un mauvais découpage du code.

### 10.12 Sécurité d'un projet Terraform

| Risque | Mesure corrective |
|---|---|
| **State exposé** | Backend distant sécurisé, RBAC, chiffrement |
| **SSH ouvert à Internet** | Filtrage par IP, Azure Bastion, désactivation du SSH public |
| **Secrets dans Git** | **Key Vault**, variables d'environnement, variables CI sécurisées, scan de secrets (`gitleaks`) |
| **Droits trop larges** | Identité Terraform au **moindre privilège** (pas Owner sur tout) |
| **Absence de tags** | Politique de tagging obligatoire (Azure Policy) |

> 💡 **Gestion des secrets :** jamais de secret dans les `.tf` ni dans un `tfvars` versionné. Utiliser **Azure Key Vault**, des **variables d'environnement**, des **variables sécurisées en CI/CD**, et pratiquer la **rotation** des identifiants.

### 10.13 Comparaison Terraform / ARM / Bicep / scripts

| Outil | Forces | Limites | Cas d'usage |
|---|---|---|---|
| **Terraform** | Multi-cloud, large écosystème, modules, `plan` lisible | Gestion rigoureuse du **state** | Organisations multi-cloud, standard IaC transverse |
| **ARM Templates** | Natif Azure, complet | Syntaxe **JSON verbeuse** | Déploiements Azure très proches de l'API |
| **Bicep** | Natif Azure, **plus lisible** qu'ARM | Moins multi-cloud | Équipes centrées Azure |
| **Scripts CLI** | Simples pour des actions ponctuelles | Peu déclaratifs, peu reproductibles | Administration, dépannage, automatisations ciblées |

### 10.14 Terraform, CI/CD et travail en équipe

**Workflow Git recommandé :** branche → modif `.tf` → `fmt` + `validate` → `plan` → **revue de code** → validation sécurité/FinOps → `apply` via pipeline contrôlé → archivage du plan et des logs.

| Rôle d'équipe | Responsabilité |
|---|---|
| Développeur | Propose les changements applicatifs |
| DevOps / Cloud Engineer | Structure le code Terraform, maintient les modules |
| Architecte | Valide la cohérence avec les principes d'architecture |
| RSSI / Sécurité | Vérifie droits, ouvertures réseau, protection des secrets |
| FinOps | Suit coûts, tags, dérives budgétaires |

**Validations automatiques en CI/CD :** `fmt -check`, `validate`, **`tflint`** (bonnes pratiques), **`tfsec`/`checkov`** (sécurité statique de l'IaC), **`gitleaks`** (secrets), `plan` sur chaque PR + approbation avant `apply`.

> 🧠 **Résultat attendu d'un projet Terraform :** pas seulement « une infrastructure qui fonctionne », mais une infrastructure **décrite proprement, lisible, versionnable, sécurisée et maîtrisée dans son cycle de vie**.

---

<a name="11"></a>
## 11. Administration & automatisation : CLI, Bash, Python (TP3)

### 11.1 Du provisionnement à l'exploitation

> 📌 **Provisionner ≠ exploiter.** Le **provisionnement** (TP1/TP2) crée les ressources (Terraform y excelle, il décrit l'état cible). L'**exploitation** (TP3) commence **après** le déploiement : administrer, inventorier, surveiller, automatiser, sécuriser et documenter au quotidien.

> 🧠 Une VM peut être **parfaitement déployée** (Terraform) et **mal exploitée** : pas de tag propriétaire, port SSH ouvert, aucune alerte CPU, aucune procédure d'arrêt, aucun suivi de coût. C'est précisément ce que traite l'exploitation.

**Familles d'actions d'exploitation :**

| Famille | Objectif | Exemples |
|---|---|---|
| **Inventaire** | Savoir ce qui existe | Lister ressources, exports CSV, tags |
| **Administration** | Modifier/piloter | Start/stop VM, resize, update tags |
| **Supervision** | Observer l'état | Azure Monitor, métriques, logs, alertes |
| **Automatisation** | Réduire les actions manuelles | Scripts Bash, Python, runbooks planifiés |
| **Sécurité** | Réduire l'exposition | RBAC, NSG, diagnostic settings, audit |
| **FinOps** | Maîtriser les coûts | Budgets, tags, arrêt des VM, suppression des orphelins |
| **Documentation** | Transmettre et pérenniser | Rapport d'exploitation, procédures, runbooks |

### 11.2 Azure CLI

> 📌 **Azure CLI (`az`) :** outil en ligne de commande pour gérer les ressources Azure, depuis un poste, **Azure Cloud Shell** ou un pipeline CI/CD.

**Pourquoi la CLI plutôt que le portail pour une tâche répétitive ?** Une commande est **rejouable à l'identique**, **documentable**, **intégrable à un script** et exécutable dans un **pipeline**. Le portail est manuel, peu reproductible, difficile à tracer et source d'erreurs.

**Formats de sortie :**

| Format | Usage |
|---|---|
| **JSON** | Traitement programmatique, scripts, Python, `jq` |
| **Table** | Lecture humaine rapide |
| **TSV** | Extraction simple dans une variable Bash (sans guillemets ni en-tête) |
| **YAML / None** | Lecture structurée / masquer la sortie |

> 📌 **JMESPath (option `--query`) :** langage de **filtrage et transformation** des sorties JSON (sélectionner des champs, filtrer, renommer des colonnes). Ex. : ne lister que les VM en cours d'exécution, ou les ressources sans tag.

### 11.3 Bash pour l'automatisation

Bash sert à **enchaîner des commandes**, factoriser des variables, contrôler les erreurs et produire des fichiers de sortie (inventaires, rapports, contrôles).

**Bonnes pratiques de scripting :**

| Bonne pratique | Pourquoi |
|---|---|
| **`set -euo pipefail`** | Arrêt sur erreur, variable non définie ou échec dans un pipe |
| **Variables centralisées** | Éviter de répéter les noms de ressources ; rejouable ailleurs |
| **Paramétrage** (`${1:-défaut}`) | Script réutilisable sur un autre environnement |
| **Vérification préalable** | Sortie propre si le RG n'existe pas |
| **Répertoires de sortie / horodatage** | Conserver les rapports, ne pas écraser l'historique |
| **Messages explicites** | Lisibilité par un autre membre de l'équipe |
| **Idempotence** | Relances sans effet de bord indésirable |
| **Journalisation** | Garder la **preuve** des contrôles/actions (audit) |
| **Pas d'action destructive sans confirmation** | Garde-fou (ex. refus d'agir sur un RG `*prod*`, confirmation avant `deallocate`) |

> 💡 **Exemples de scripts d'exploitation ShopEasy :** `inventory.sh` (inventaire + synthèse), `vm-power.sh` (start/stop/deallocate/status avec garde-fous), `healthcheck.sh` (contrôle de santé renvoyant un **code de sortie** 0/1 exploitable en CI/cron).

### 11.4 Python et le SDK Azure

> 📌 **SDK Azure pour Python :** bibliothèques permettant d'interagir par programme avec les services Azure. Python devient préférable à Bash quand le besoin dépasse l'enchaînement de commandes : **traitement structuré, croisement/enrichissement de données, appels API, génération de rapports, intégration** avec d'autres systèmes.

| Bibliothèque | Rôle |
|---|---|
| `azure-identity` | Authentification (**`DefaultAzureCredential`**) |
| `azure-mgmt-resource` | Gestion des resource groups et ressources ARM |
| `azure-mgmt-compute` | Gestion des machines virtuelles |
| `azure-mgmt-monitor` | Accès à certaines fonctions de monitoring |

> 📌 **`DefaultAzureCredential` :** chaîne d'authentification qui tente successivement plusieurs sources (variables d'environnement, **identité managée**, session `az login`…) pour obtenir un **token Microsoft Entra ID**, **sans coder de secret** dans le script.

**Bash ou Python ?**

| Besoin | Outil adapté |
|---|---|
| Enchaîner des commandes, contrôles rapides, exports bruts | **Bash** |
| Enrichir/croiser des données, produire un format structuré (CSV/JSON), intégrer une API | **Python + SDK** |

### 11.5 Runbook

> 📌 **Runbook :** **procédure d'exploitation documentée** décrivant comment réaliser une action de façon fiable (démarrer/arrêter un environnement, vérifier la santé d'un service, restaurer un fichier, réagir à une alerte). L'ensemble des scripts du TP3 forme un **mini-runbook** permettant à une autre personne de reprendre l'administration **sans dépendre du portail**.

### 11.6 Control-plane vs data-plane (RBAC du stockage)

> 📌 **Control-plane vs data-plane :** Azure sépare la gestion **de** la ressource (créer/configurer un Storage Account via ARM = *control-plane*) de l'accès **au contenu** de la ressource (lire/écrire des blobs = *data-plane*).

> ⚠️ Être **Owner** de l'abonnement donne les droits **control-plane** mais **pas** data-plane. Pour déposer un blob avec `--auth-mode login`, il faut un **rôle data-plane** précis (ex. **`Storage Blob Data Contributor`**) attribué **au scope du compte** — préférable à la clé d'accès partagée (`--auth-mode key`), qui est un secret à large portée, non auditable par identité.

### 11.7 IaC vs script d'exploitation

| | **IaC (Terraform)** | **Script d'exploitation (Bash/Python)** |
|---|---|---|
| **Nature** | **Déclaratif** (état cible) | **Impératif** (actions ponctuelles) |
| **Rôle** | **Construit** et fait évoluer l'infra | **Exploite** l'existant (inventaire, arrêt, contrôle) |
| **Exemple** | Créer le VNet, les VM, le LB | Lister les VM, désallouer, vérifier la santé |

> *L'un construit, l'autre administre.*

---

<a name="12"></a>
## 12. Monitoring & observabilité (TP3/TP4)

### 12.1 Monitoring, observabilité, audit, sécurité

| Concept | Question centrale | Exemple ShopEasy |
|---|---|---|
| **Monitoring** | *Est-ce que ça fonctionne ?* | La CPU d'une VM dépasse 85 % |
| **Observabilité** | *Pourquoi ça ne fonctionne pas ?* | Les logs montrent une erreur de connexion à la base |
| **Audit** | *Qui a fait quoi ?* | Un utilisateur a modifié une règle réseau |
| **Sécurité** | *Le système est-il protégé ?* | Un port d'administration est exposé à Internet |

> 📌 **Monitoring :** collecter et **surveiller des indicateurs prédéfinis** pour vérifier que le système fonctionne (*si* ça marche). **Le monitoring constate.**
> 📌 **Observabilité :** **comprendre l'état interne** d'un système à partir des signaux qu'il produit (*pourquoi* ça se comporte ainsi). **L'observabilité explique.** Essentielle pour les architectures distribuées.

### 12.2 Les trois signaux classiques

| Signal | Définition | Exemple |
|---|---|---|
| **Métrique** | Valeur **numérique** mesurée dans le temps | CPU %, mémoire, latence, nombre de requêtes |
| **Log** | **Événement textuel** détaillé produit par une ressource/app | Erreur applicative, changement de configuration |
| **Trace** | Suivi d'une **requête à travers plusieurs composants** | Parcours d'une requête dans un système distribué |

> 🧠 *Une **métrique** indique souvent qu'un problème existe ; un **log** aide à comprendre le contexte ; une **trace** suit le chemin d'une requête.*

**Métriques vs logs :**

| Critère | Métriques | Logs |
|---|---|---|
| Nature | Numérique agrégée | Événements détaillés |
| Granularité | Périodique | Variable selon les événements |
| Usage typique | Alerte rapide sur seuil | Diagnostic, investigation |
| Coût | Plus prévisible | Dépend du volume ingéré et conservé |

### 12.3 Azure Monitor et ses composants

> 📌 **Azure Monitor :** service **central de supervision** d'Azure. Il **collecte, analyse et exploite** métriques, logs et alertes des ressources, et alimente tableaux de bord et requêtes.

Chaîne conceptuelle : **Sources** (VM, SQL, Storage, VNet) → **Collecte** (metrics, logs, events) → **Analyse** (dashboards, requêtes, workbooks) → **Action** (alertes, tickets, corrections).

| Composant | Rôle |
|---|---|
| **Azure Monitor Metrics** | Stockage/analyse de **métriques numériques** dans le temps |
| **Azure Monitor Logs** | Centralisation/analyse de **logs** |
| **Log Analytics Workspace** | Espace de travail pour **stocker, interroger (KQL) et corréler** les logs |
| **Alert Rules** | Règles déclenchées quand une **condition** est atteinte |
| **Action Groups** | Destinataires/actions associés à une alerte |
| **Workbooks** | Rapports interactifs (texte + visualisations + requêtes) |
| **Dashboards** | Tableaux de bord synthétiques dans le portail |
| **Activity Log** | Journal des **opérations de gestion** (voir §15) |

> 📌 **Log Analytics Workspace :** espace **centralisé** pour stocker, **interroger en KQL** (*Kusto Query Language*) et **corréler** les logs/métriques de plusieurs ressources. Base de l'observabilité. SKU type **PerGB2018** (facturation à l'ingestion), rétention paramétrable (ex. 30 j en dev).

> 📌 **Diagnostic settings :** configuration qui **exporte** les logs/métriques d'une ressource vers un workspace Log Analytics (ou Storage, Event Hub). Ex. ShopEasy : raccordement du **Storage** (transactions + logs blob) et de l'**Activity Log** au workspace.

> 💡 **Métriques de plateforme :** certaines métriques (CPU, réseau, disque, disponibilité) remontent **nativement, sans agent**. Les **logs invité** (syslog, logs Nginx) et compteurs mémoire/disque fins nécessitent l'**Azure Monitor Agent (AMA)** + une **Data Collection Rule (DCR)** pointant vers le workspace.

### 12.4 Construire une stratégie de monitoring

> ⚠️ **Piège :** vouloir tout surveiller sans priorisation. Une stratégie efficace **commence par les objectifs métier et opérationnels**, pas par les courbes techniques.

**Question à se poser avant de créer une alerte :** *« Si cette alerte se déclenche, une personne doit-elle **vraiment agir** ? »* Si non → c'est une **information de dashboard**, pas une alerte.

**Axes d'indicateurs (couverture complète) :**

| Axe | Indicateurs | Interprétation |
|---|---|---|
| **Disponibilité** | État des VM, taux d'erreur HTTP, santé des backends LB | Indisponibilité / dégradation |
| **Performance** | CPU, mémoire, disque, latence, temps de réponse | Saturation / sous-dimensionnement |
| **Capacité** | Taille stockage, nombre de requêtes/connexions | Anticiper la croissance |
| **Sécurité** | Connexions suspectes, changements IAM/RBAC, ports exposés | Comportements anormaux |
| **Coût** | Coût par service/tag, budget consommé | Dérives financières |
| **Qualité d'exploitation** | Nombre d'incidents, MTTR, alertes critiques | Efficacité opérationnelle |

### 12.5 SLI, SLO, SLA

| Sigle | Définition | Exemple |
|---|---|---|
| **SLI** (*Service Level Indicator*) | **Indicateur** mesurable | Taux de disponibilité |
| **SLO** (*Service Level Objective*) | **Objectif interne** fixé sur un indicateur | 99,5 % de disponibilité/mois |
| **SLA** (*Service Level Agreement*) | **Engagement contractuel** avec un client/partenaire | 99,9 % garantis (pénalités si non respecté) |

### 12.6 Alertes et gestion des incidents

> 📌 **Alerte :** signal **automatique** déclenché quand une **condition** (seuil) est franchie. Une bonne alerte doit être **actionnable** : associée à un **destinataire**, une **criticité** et une **procédure de traitement** (runbook).

**Composants d'une alerte :**

| Élément | Description |
|---|---|
| **Condition** | Situation qui déclenche (ex. CPU moyen > 80 %) |
| **Période / fenêtre** | Durée d'évaluation (ex. 5 min) — **lisse** les pics transitoires |
| **Fréquence d'évaluation** | À quelle cadence la condition est testée (ex. 1 min) |
| **Sévérité** | Niveau : Sev 0 (critique) → Sev 4 (information) |
| **Action Group** | Qui/quoi est notifié (e-mail, SMS, webhook, ITSM) |
| **Runbook** | Procédure de diagnostic et correction |

> 📌 **Action Group :** définit **qui est notifié et comment** quand une alerte se déclenche (e-mail, SMS, webhook, ITSM, canal d'exploitation).

> 📌 **Agrégation `Average` vs `Maximum` :** `Average` surveille une **charge soutenue** (ce qu'on veut pour le CPU) ; `Maximum` capte un **pic instantané**.

> 📌 **Baseline :** mesure de référence de l'état normal (ex. CPU au repos ~0,3 %), qui sert à **calibrer le seuil** d'alerte.

> 📌 **MTTR (*Mean Time To Repair/Resolve*) :** temps moyen de résolution d'un incident. Une procédure d'alerte claire **réduit le MTTR**.

**Cycle de gestion d'incident :** Détecter → Qualifier → Diagnostiquer → Corriger → Capitaliser.

### 12.7 La fatigue d'alerte

> ⚠️ **Alert fatigue (fatigue d'alerte) :** *« Trop d'alertes tue l'alerte. »* Des seuils **trop bas** → faux positifs → les équipes **ignorent** les notifications et **ratent** les vrais incidents.

| Mauvais réglage | Conséquence |
|---|---|
| **Seuil trop bas / fenêtre trop courte** | **Faux positifs**, fatigue d'alerte (ex. `CPU > 40 %` sur 1 min se déclenche à chaque déploiement) |
| **Seuil trop haut / fenêtre trop longue** | **Détection tardive** : on est prévenu une fois le service déjà dégradé (ex. `CPU > 98 %` sur 30 min) |
| **Scope trop large** | On ne sait pas **quelle** ressource est en cause |

**Comment l'éviter :** distinguer les criticités (critique = action immédiate / avertissement = analyse / info = dashboard) ; calibrer sur la **baseline** + fenêtre de lissage ; n'alerter que sur l'**actionnable** ; regrouper via les Action Groups ; **réviser régulièrement** les règles.

### 12.8 Sonde synthétique & disponibilité réelle

> 📌 **Sonde de disponibilité synthétique (URL ping test) :** test **externe** qui interroge périodiquement le site (via l'IP du Load Balancer) et vérifie le **code 200 + le contenu + le temps de réponse**. Mesure la disponibilité **réellement perçue par l'utilisateur** (chaîne complète DNS → LB → VM → Nginx → réponse).

> 💡 La métrique `VmAvailabilityMetric = 1` indique seulement que la VM **tourne au niveau plateforme**, **pas** que le site répond correctement. Les métriques d'**infrastructure** (CPU, réseau, dispo plateforme) **ne suffisent pas** à diagnostiquer un incident **applicatif** (Nginx qui renvoie des 500, requête lente) → il faut des **logs applicatifs / codes HTTP / latence** (via AMA ou **Application Insights**).

### 12.9 Tableau de bord (dashboard)

> 📌 **Dashboard d'exploitation :** vue **synthétique de pilotage** répondant aux questions de décision : *le service fonctionne-t-il ? coûte-t-il trop cher ? est-il sécurisé ? que corriger en priorité ?* Il sert à **décider**, pas seulement à afficher des courbes. Pour une DSI : état des VM, CPU, trafic, stockage, **coûts**, **alertes récentes**, lien vers les **journaux**.

---

<a name="13"></a>
## 13. FinOps : maîtrise des coûts

### 13.1 Définition

> 📌 **FinOps :** discipline combinant **Finance, technologie et Opérations** pour **comprendre, piloter et optimiser les dépenses cloud**. Ce n'est **pas** seulement réduire les coûts : il s'agit de **maximiser la valeur** produite par les ressources consommées.

> 🧠 Le cloud rend la dépense **plus flexible** (OPEX) mais aussi **plus facile à disperser**. Sans tags, budgets, alertes et gouvernance, on ne sait plus *qui consomme quoi, pourquoi et pour quelle valeur métier*.

### 13.2 Les trois grands objectifs FinOps

1. **Rendre les coûts visibles** — comprendre les dépenses par service, projet, équipe, environnement.
2. **Responsabiliser les équipes** — associer la consommation à des usages et à des **propriétaires**.
3. **Optimiser en continu** — ajuster ressources, architectures, modes de facturation et pratiques.

### 13.3 Réduction vs optimisation

> 📌 **Réduire ≠ optimiser.**
> - **Réduire** = baisser la dépense, parfois **au détriment du service** (supprimer, sous-dimensionner aveuglément).
> - **Optimiser** = obtenir le **meilleur rapport valeur/coût** : bon dimensionnement, suppression du **gaspillage** (ressources oubliées, surdimensionnées, facturées à vide), choix du bon niveau de service, **sans dégrader la valeur métier**.
> La cible FinOps est l'**optimisation**.

### 13.4 Outils Azure utiles au FinOps

| Outil | Rôle |
|---|---|
| **Azure Cost Management** | Analyse, suivi et optimisation des coûts, **budgets**, alertes |
| **Azure Pricing Calculator** | **Estimer** un coût **avant** déploiement |
| **Budgets** | Définir un seuil financier + notifications |
| **Cost alerts** | Notification lors de dépassements/anomalies |
| **Tags** | Affecter les coûts par projet/app/équipe/environnement |
| **Reservations / Savings Plans** | Réduction pour des usages **prévisibles** (engagement 1–3 ans) |
| **Azure Advisor** | Recommandations (coût, sécurité, performance, fiabilité) |

### 13.5 Coût constaté vs coût prévisionnel

> 📌 **Coût constaté :** dépense **réelle déjà facturée** (historique). N'apparaît qu'après **24–48 h** sur un abonnement récent.
> 📌 **Coût prévisionnel (*forecast*) :** **projection** de la dépense à venir selon la tendance → **anticiper** un dépassement **avant** qu'il survienne.

> 💡 À défaut de coût constaté, on estime via l'**API Azure Retail Prices** (prix unitaires officiels). Ex. ShopEasy : `Standard_B2ats_v2` ≈ 0,00972 $/h.

### 13.6 Pièges de coût : ressources facturées à vide & orphelines

> ⚠️ Certaines ressources facturent **même à trafic nul** : **Load Balancer**, **IP publiques statiques**, **disques managés**, **base provisionnée**. Seul le **compute d'une VM** est élastique (annulable par **désallocation**).

> 📌 **Ressource orpheline :** ressource facturée mais **non utilisée** (disque non attaché, IP publique non associée). À détecter et supprimer (« coûts invisibles »).

**Exemple chiffré ShopEasy (≈ 47 $/mois en 24/7) :** Load Balancer (~39 %) + compute 2 VM (~30 %) + 3 IP publiques (~23 %) = **~92 %** du coût.

### 13.7 Leviers d'optimisation FinOps

| Levier | Effet | Limite |
|---|---|---|
| **Désallouer les VM hors usage** | Annule le coût compute (≈ –70 % si usage 50 h/sem) | Indisponibilité de l'environnement |
| **Détruire l'environnement entre séances** (`terraform destroy`) | Coût → ≈ 0, recréable à l'identique | Réservé aux environnements non permanents |
| **Réduire les IP publiques** (Bastion) | Économie + surface d'attaque réduite | Plus d'accès web direct par VM |
| **Dimensionner correctement** | Évite le surdimensionnement | Surveiller `CPU Credits` avant downsize d'un burstable |
| **Lifecycle policy** sur le Blob | Plafonne l'accumulation des versions | — |
| **Réservations / Savings Plans** | Réduction sur usage stable | Engagement |
| **Tags + budgets + alertes** | Imputation + détection des dérives | Le budget **alerte mais ne bloque pas** la dépense |

> ⚠️ Un **budget Azure ne remplace pas une gouvernance** : il alerte sur un montant mais ne dit pas **quelle** ressource est en cause, **qui** est responsable, ni laquelle peut être arrêtée. Sans **tags** et organisation, on voit la dérive sans pouvoir agir.

---

<a name="14"></a>
## 14. Sécurité cloud (TP4)

### 14.1 Le modèle de responsabilité partagée

> 📌 **Responsabilité partagée :** dans le cloud, la sécurité est **partagée** entre le fournisseur et le client.

| Responsabilité | Périmètre |
|---|---|
| **Fournisseur cloud (Microsoft)** | Datacenters, matériel, hyperviseur, disponibilité des services Azure, sécurité physique |
| **Client** | Comptes, **rôles**, **données**, **configuration réseau**, **chiffrement**, **journalisation**, gouvernance |
| **Partagé** | Mises à jour, supervision, continuité — selon le service (IaaS > PaaS > SaaS) |

> 🧠 **Utiliser Azure ne rend pas une application sécurisée automatiquement.** Une mauvaise configuration IAM, un stockage public ou un port d'administration ouvert introduisent des **risques majeurs**. La sécurité est de la responsabilité du client sur **ce qu'il administre**.

### 14.2 Identité et accès

La sécurité cloud **commence par l'identité** : Microsoft Entra ID + RBAC gèrent **qui peut accéder à quoi avec quels droits**.

| Notion | Rôle |
|---|---|
| **Utilisateur** | Personne physique ou compte associé |
| **Groupe** | Ensemble d'utilisateurs aux droits communs |
| **Rôle RBAC** | Ensemble d'autorisations (Owner/Contributor/Reader…) |
| **Scope** | Niveau d'application des droits (MG / subscription / RG / resource) |

→ **Moindre privilège** (§9.2), **comptes nominatifs**, **MFA**, **revue des rôles**.

### 14.3 Sécurité réseau

| Bonne pratique | Justification |
|---|---|
| **Fermer les ports inutiles** | Réduit la surface d'attaque |
| **Limiter SSH/RDP à des IP autorisées** (ou Bastion) | Évite l'administration exposée publiquement |
| **Isoler les bases de données** | Une base ne doit pas être joignable directement depuis Internet |
| **Segmenter les subnets** | Sépare web / applicatif / données (mouvements latéraux limités) |
| **Journaliser les changements** | Facilite l'audit et l'investigation |

### 14.4 Microsoft Defender for Cloud

> 📌 **Microsoft Defender for Cloud :** service de **gestion de la posture de sécurité (CSPM)** et de **protection des charges de travail (CWP)**. Analyse la posture, propose des recommandations et protège les workloads.

| Concept | Définition |
|---|---|
| **Secure Score** | Indicateur **synthétique** de la posture de sécurité |
| **Recommendations** | Actions proposées pour corriger les faiblesses |
| **Regulatory compliance** | Suivi de conformité selon des cadres de référence (CIS, ISO…) |
| **Workload protection** | Protections avancées selon les services (servers, storage, SQL…) |

> 🧠 **Une recommandation de sécurité doit être traduite en action.** Toutes ne se valent pas : on les **priorise** selon l'exposition de la ressource, la sensibilité des données, le coût de correction, l'impact opérationnel, les exigences de conformité et la criticité métier. Une DSI attend une **priorisation**, pas une liste brute de problèmes.

### 14.5 Chiffrement

> 📌 **Chiffrement au repos** (données stockées, ex. SSE/TDE) et **en transit** (HTTPS/TLS 1.2). Activé par défaut sur de nombreux services Azure.

> ⚠️ **Le chiffrement ne suffit pas** à sécuriser une ressource. Il protège les données au repos et en transit, mais **pas** contre un **accès public** mal configuré, des **droits excessifs**, un **port exposé** ou l'**absence de logs**. La sécurité est **multi-couches** : réseau, identité, configuration, audit — le chiffrement n'en est qu'une.

### 14.6 Risques typiques (cas ShopEasy) et mesures

| Risque | Impact | Mesure corrective |
|---|---|---|
| **SSH ouvert à Internet** | Intrusion, force brute, compromission VM | Restreindre à l'IP admin, **Azure Bastion**, MFA, accès *just-in-time* |
| **Base de données exposée** | Vol/altération des données | Accès privé, **Private Endpoint**, pare-feu fermé, comptes limités |
| **Stockage public** | Fuite de documents (RGPD) | `allowBlobPublicAccess=false`, RBAC/SAS limités |
| **Droits trop larges (Owner)** | Erreur/compromission à fort impact | **RBAC moindre privilège**, revue, MFA, PIM |
| **Absence de logs/alertes** | Incidents non détectés | Azure Monitor, Activity Log, diagnostic settings, Defender |
| **Defender non activé** | Pas de détection ni de posture | Activer les plans Defender (CSPM, servers, storage) |
| **MAJ système non vérifiées** | Vulnérabilités non corrigées | **Azure Update Manager** |

---

<a name="15"></a>
## 15. Audit, traçabilité & gouvernance avancée

### 15.1 Pourquoi auditer ?

L'audit répond aux questions : *Qui a modifié cette ressource ? Quand un changement a-t-il eu lieu ? Quelle action a provoqué un incident ? Les ressources critiques sont-elles correctement journalisées ? Peut-on **prouver** qu'une mesure de sécurité existe ?*

### 15.2 Sources de traces dans Azure

| Source | Utilité |
|---|---|
| **Activity Log** | Opérations de **gestion** sur les ressources Azure (*control-plane*) |
| **Resource Logs** | Logs spécifiques produits par certains services (*data-plane*) |
| **Entra ID logs** | Connexions, identités, activités liées aux comptes |
| **Diagnostic settings** | Export des logs vers Log Analytics / Storage / Event Hub |
| **Defender for Cloud** | Alertes et recommandations de sécurité |
| **Azure Policy** | Conformité des ressources aux règles de gouvernance |

### 15.3 L'Activity Log

> 📌 **Activity Log (journal d'activité) :** journal des **opérations de gestion** réalisées sur les ressources via ARM (création, modification, suppression, changement de droits). Il trace **qui** (auteur), **quoi** (opération), **quand** (horodatage) et **avec quel résultat** (`Started`/`Succeeded`/`Failed`). C'est la **source de vérité** des changements d'infrastructure.

> 📌 **Log technique vs log d'activité :**
> - **Log technique** (système/applicatif : syslog, logs Nginx) → décrit le **fonctionnement interne** d'une ressource/app (*data-plane*). « Ce que fait l'application. »
> - **Log d'activité** (Activity Log) → trace les **opérations de gestion** sur l'infrastructure (*control-plane*). « Ce que l'on fait à l'infrastructure. »

> 💡 L'Activity Log trace aussi les **échecs** (`Failed`), précieux pour **diagnostiquer** une opération qui n'a pas abouti. Centraliser l'Activity Log dans Log Analytics permet des **requêtes KQL**, des **alertes** sur opérations sensibles (RBAC, NSG, suppressions), des **revues périodiques** et un **reporting de conformité**.

### 15.4 Notion de preuve

> 📌 **Preuve d'exploitation :** en contexte professionnel, il ne suffit **pas de dire** qu'une ressource est sécurisée — il faut pouvoir le **démontrer**. Preuves possibles : capture de configuration, export de logs, tableau de bord, rapport d'audit, historique d'activité, règle Azure Policy, preuve de revue d'accès.

### 15.5 Information parfois manquante pour reconstituer un incident

Le **contexte applicatif** (le « pourquoi »), les **logs invité/applicatifs non centralisés**, l'**intention** derrière une action, les **accès data-plane**, et la **corrélation temporelle** entre un changement et un symptôme. → D'où l'intérêt de **centraliser** logs d'activité **et** logs techniques dans un même workspace.

---

<a name="16"></a>
## 16. Disponibilité, résilience & analyse de risques

### 16.1 Notions clés de résilience

| Notion | Définition |
|---|---|
| **SPOF** (*Single Point Of Failure*) | **Point de défaillance unique** : un composant dont la panne arrête tout le système (ex. serveur unique ShopEasy). |
| **RPO** (*Recovery Point Objective*) | **Perte de données maximale acceptable** (mesurée en temps) → dépend de la fréquence des sauvegardes. |
| **RTO** (*Recovery Time Objective*) | **Temps de reprise maximal acceptable** après un incident. |
| **MTTR** (*Mean Time To Repair*) | Temps moyen de résolution d'un incident. |
| **Redondance** | Duplication de composants pour tolérer une panne (ex. 2 VM + LB). |
| **Application sans état (*stateless*)** | App ne stockant pas de session locale → la répartition de charge est transparente. |

> 🧠 Supprimer un **SPOF** applicatif = déployer **plusieurs instances** derrière un **Load Balancer** avec **sonde de santé**. Pour une vraie résilience : ajouter le **multi-zone** (Availability Zones), une base **hautement disponible** (failover group), un stockage **redondé** (ZRS/GRS), des **sauvegardes testées** et des objectifs **RPO/RTO** définis.

### 16.2 Analyse de scénarios d'incident (ShopEasy)

| Scénario | Impact | Réponse attendue |
|---|---|---|
| **Une VM web tombe** | Service continue sur l'autre VM (sonde la retire), capacité ÷ 2 | Plusieurs VM + LB + sonde **(déjà couvert)** ; multi-zone + autoscale pour aller plus loin |
| **Le Load Balancer est mal configuré** | Trafic mal routé/rejeté même si les VM sont saines | Vérifier sonde/règle/pool, **IaC** pour une config reproductible, alertes sur la santé du LB |
| **La base devient indisponible** | Erreurs fonctionnelles malgré un web disponible | Niveau SQL avec **HA/SLA**, **PITR**, failover group, monitoring SQL |
| **Le Storage est mal configuré** | Documents inaccessibles ou **exposés** | Accès privé, versioning + soft-delete, Private Endpoint, alertes |
| **Une zone est indisponible** | Perte simultanée si les VM sont dans le même datacenter | **Déploiement multi-zone** + LB zone-redundant |

### 16.3 Matrice de risques (méthode)

> 📌 **Analyse de risques :** identifier les **scénarios défavorables**, estimer leur **probabilité** et leur **impact**, puis proposer une **mesure corrective**, et **prioriser**.

| Priorité | Critère |
|---|---|
| **Haute** | Risque de compromission, indisponibilité majeure, coût important imminent |
| **Moyenne** | Amélioration nécessaire mais sans urgence immédiate |
| **Basse** | Optimisation utile mais non bloquante |

---

<a name="17"></a>
## 17. Méthodologie : choix de services & note DSI

### 17.1 Partir du besoin, pas du service

> 🧠 Un bon architecte **ne commence pas par choisir des services**. Il part des **besoins** : qui utilise l'application ? quelles données ? quels niveaux de disponibilité attendus ? quelles contraintes de sécurité ? quel budget acceptable ?

**Questions de cadrage (par besoin) :** *Quelle fonction doit être rendue ? Quel niveau de service attendu ? Quelle responsabilité voulons-nous garder ? Quel risque réduire ? Quel coût accepter ?*

**Matrice de décision (ShopEasy) :**

| Besoin | Option simple | Option cible | Critère de choix |
|---|---|---|---|
| Application web | VM | App Service ou VM + LB | Contrôle, migration, exploitation |
| Base SQL | SQL sur VM | **Azure SQL Database** | Administration, sauvegarde, disponibilité |
| Documents | Disque VM | **Storage Account** | Durabilité, partage, versioning |
| Accès admin | SSH public | **Bastion** / restriction IP | Sécurité et audit |
| Monitoring | Aucun | **Azure Monitor** | Exploitabilité |
| Coûts | Estimation manuelle | **Pricing Calculator + Budget** | Gouvernance FinOps |

### 17.2 Lecture critique d'une architecture

Questions de revue : les ressources exposées à Internet sont-elles identifiées ? la base est-elle protégée des accès directs ? existe-t-il une supervision ? les coûts sont-ils estimés et attribuables ? l'architecture a-t-elle un **SPOF** ? les droits d'administration sont-ils limités ? les données importantes sont-elles sauvegardées/versionnées ? les choix sont-ils justifiés par le **besoin métier** ?

### 17.3 La note de recommandations DSI

> 📌 **Note DSI :** document de **décision** à destination de la Direction des Systèmes d'Information. Elle ne se limite **pas** à une liste de services techniques : elle relie **constats techniques**, **impacts métier**, **risques**, **coûts** et **priorités**. Une DSI attend une décision **argumentée, lisible et priorisée**.

**Structure recommandée :**
1. **Contexte** (situation, limites, enjeux métier)
2. **Constats / état actuel** (architecture, points observés)
3. **Risques** (techniques, financiers, sécurité)
4. **Recommandations** (actions proposées, priorité, justification)
5. **Plan d'action** (court / moyen / long terme)
6. **Indicateurs de suivi** (métriques de vérification)
7. **Conclusion**

### 17.4 Les 4 piliers d'une plateforme cloud mature

> 🧠 Une plateforme Azure mature repose sur **4 piliers opérationnels** : **Observabilité**, **FinOps**, **Sécurité** et **Gouvernance**. Ils transforment une architecture **technique** en un **système d'information exploitable** par une organisation. *Une infrastructure cloud n'est pas prête pour la production si elle n'est pas surveillée, auditée, gouvernée et optimisée.*

---

<a name="18"></a>
## 18. Annexes

### 18.1 Correspondance conceptuelle AWS ↔ Azure

| AWS | Azure |
|---|---|
| VPC | **Virtual Network (VNet)** |
| Subnet | **Subnet** |
| Security Group | **Network Security Group (NSG)** |
| EC2 | **Virtual Machine** |
| Elastic Load Balancing | **Azure Load Balancer / Application Gateway** |
| S3 | **Storage Account / Blob Storage** |
| RDS | **Azure SQL Database / Azure Database for MySQL-PostgreSQL** |
| IAM | **Microsoft Entra ID + RBAC + Managed Identities** |
| CloudWatch | **Azure Monitor** |
| AWS Pricing Calculator | **Azure Pricing Calculator** |
| CloudFormation | **ARM Templates / Bicep** (Terraform = multi-cloud) |

### 18.2 Récapitulatif des services Azure du projet

| Service | Catégorie | Modèle | Rôle dans ShopEasy |
|---|---|---|---|
| **Resource Group** | Organisation | Gouvernance | Cycle de vie commun, droits, coûts |
| **Virtual Network + Subnets** | Réseau | IaaS | Réseau privé isolé, segmentation |
| **Network Security Group** | Réseau/Sécurité | IaaS | Filtrage des flux (80/443/22/1433) |
| **Azure Load Balancer** | Réseau | IaaS | Répartition de charge L4 + sonde |
| **Application Gateway** | Réseau | IaaS | (Cible prod) L7 + TLS + WAF |
| **Azure Bastion** | Réseau/Sécurité | PaaS | Accès SSH/RDP sans IP publique |
| **Virtual Machines** | Calcul | IaaS | 2 serveurs web (Nginx) redondants |
| **Azure App Service** | Calcul | PaaS | (Alternative) hébergement web managé |
| **Storage Account (Blob)** | Stockage | PaaS | Documents clients, exports, archives |
| **Azure SQL Database** | Données | PaaS | Base relationnelle managée |
| **Microsoft Entra ID + RBAC** | Identité | Gouvernance | Identités, droits, moindre privilège |
| **Azure Monitor** | Observabilité | Gouvernance | Métriques, logs, alertes, dashboards |
| **Log Analytics Workspace** | Observabilité | Gouvernance | Centralisation et requêtes KQL |
| **Azure Cost Management** | FinOps | Gouvernance | Suivi, budgets, alertes de coût |
| **Microsoft Defender for Cloud** | Sécurité | Gouvernance | Posture, recommandations, Secure Score |
| **Azure Policy** | Gouvernance | Gouvernance | Imposer/auditer des règles |
| **Terraform** | IaC | Outil | Décrire l'infra en code (déclaratif) |
| **Azure CLI / SDK Python** | Administration | Outil | Exploiter, automatiser, inventorier |

### 18.3 Glossaire des termes et sigles

| Terme / sigle | Définition |
|---|---|
| **Availability Zone (AZ)** | Datacenter(s) physiquement séparé(s) au sein d'une région (résilience) |
| **Backend pool** | Ensemble des instances cibles d'un Load Balancer |
| **Baseline** | État normal de référence d'une métrique (sert à calibrer les seuils) |
| **Bicep** | Langage IaC natif Azure, plus lisible qu'ARM |
| **Blob Storage** | Stockage objet pour fichiers non structurés |
| **CAPEX / OPEX** | Dépense d'investissement / d'exploitation |
| **CIDR** | Notation des plages d'adresses IP (ex. `10.10.0.0/16`) |
| **Cloud-init** | Provisionnement automatique au 1ᵉʳ démarrage d'une VM Linux |
| **Control-plane / data-plane** | Gérer la ressource (ARM) / accéder à son contenu |
| **CSPM** | *Cloud Security Posture Management* (posture de sécurité) |
| **DefaultAzureCredential** | Chaîne d'authentification SDK sans secret en dur |
| **DRY** | *Don't Repeat Yourself* (ne pas dupliquer le code) |
| **Drift** | Écart entre l'état réel et le code IaC |
| **DTU / vCore** | Modèles d'achat de capacité Azure SQL |
| **Élasticité** | Capacité d'ajuster les ressources à la demande |
| **FinOps** | Discipline de pilotage et d'optimisation des coûts cloud |
| **HCL** | *HashiCorp Configuration Language* (langage Terraform) |
| **IaaS / PaaS / SaaS** | Infrastructure / Platform / Software as a Service |
| **IaC** | *Infrastructure as Code* |
| **JMESPath** | Langage de requête des sorties JSON (`--query`) |
| **KQL** | *Kusto Query Language* (requêtes Log Analytics) |
| **Load Balancer** | Répartiteur de trafic (couche 4) |
| **LRS / ZRS / GRS** | Redondance locale / de zone / géographique |
| **Managed Identity** | Identité Azure gérée, sans secret, pour l'authentification de services |
| **MFA** | *Multi-Factor Authentication* |
| **Moindre privilège** | N'accorder que les droits strictement nécessaires |
| **MTTR** | Temps moyen de résolution d'un incident |
| **NSG** | *Network Security Group* (filtrage réseau) |
| **Observabilité** | Comprendre le « pourquoi » d'un comportement système |
| **PIM** | *Privileged Identity Management* (élévation temporaire de droits) |
| **PITR** | *Point-In-Time Restore* (restauration à un instant donné) |
| **Private Endpoint** | Accès privé à un service PaaS via une IP du VNet |
| **Provider** | Plugin Terraform pilotant une plateforme (ex. azurerm) |
| **RBAC** | *Role-Based Access Control* (droits par rôle) |
| **Region** | Zone géographique de déploiement |
| **Resource Group** | Conteneur logique de ressources (cycle de vie commun) |
| **RGPD** | Règlement général sur la protection des données |
| **RPO / RTO** | Perte de données / temps de reprise maximaux acceptables |
| **Runbook** | Procédure d'exploitation documentée |
| **SAS** | *Shared Access Signature* (jeton d'accès à durée limitée au stockage) |
| **Secure Score** | Indicateur synthétique de posture (Defender) |
| **SLI / SLO / SLA** | Indicateur / objectif interne / engagement contractuel de niveau de service |
| **SPOF** | *Single Point Of Failure* (point de défaillance unique) |
| **SSE / TDE** | Chiffrement au repos (Storage / SQL) |
| **State (tfstate)** | Lien entre code Terraform et ressources réelles |
| **Subnet** | Sous-réseau d'un VNet |
| **Tag** | Métadonnée clé=valeur de gouvernance |
| **Tenant** | Annuaire d'identité (Entra ID) |
| **Terraform** | Outil IaC déclaratif multi-cloud (HashiCorp) |
| **VNet** | *Virtual Network* (réseau privé Azure) |
| **WAF** | *Web Application Firewall* (pare-feu applicatif L7) |
| **Well-Architected Framework** | Cadre d'évaluation d'architecture (5 piliers) |

---

### 18.4 Banque de questions-réponses type (révision)

#### A. Cloud, modèles & Azure de base

1. **Qu'est-ce que le cloud computing ?** Un modèle de fourniture de ressources informatiques à la demande, via le réseau, configurables, mesurables et facturées à l'usage.
2. **Citez les propriétés fondamentales du cloud.** Élasticité, facturation à l'usage, automatisation, services managés.
3. **Différence CAPEX / OPEX ?** CAPEX = investissement (achat) ; OPEX = dépense d'exploitation récurrente à l'usage (modèle cloud).
4. **Différence IaaS / PaaS / SaaS ?** Niveau d'abstraction croissant : IaaS = infrastructure (VM, réseau) ; PaaS = plateforme managée (App Service, Azure SQL) ; SaaS = logiciel complet (M365).
5. **Azure SQL Database : IaaS ou PaaS ?** **PaaS**.
6. **Que signifie PaaS ?** *Platform as a Service*.
7. **Rôle d'un Resource Group ?** Regrouper des ressources à cycle de vie commun pour les administrer, sécuriser (RBAC), taguer, suivre en coût et supprimer ensemble.
8. **Différence région / zone de disponibilité ?** Région = zone géographique ; zone de disponibilité = datacenters physiquement séparés au sein d'une région.
9. **Que sont les 5 piliers du Well-Architected Framework ?** Fiabilité, Sécurité, Optimisation des coûts, Excellence opérationnelle, Efficacité des performances.

#### B. Réseau & disponibilité

10. **Quel service crée un réseau privé logique ?** Azure Virtual Network (VNet).
11. **À quoi sert un NSG ?** Filtrer le trafic réseau entrant/sortant (par port, protocole, source/destination, priorité).
12. **Pourquoi plusieurs subnets ?** Séparer les rôles (web/données/admin) et appliquer des règles de sécurité différentes (cloisonnement, moindre privilège réseau).
13. **Pourquoi ne pas ouvrir SSH à tout Internet ?** Pour réduire la surface d'attaque (scans, force brute) ; restreindre à l'IP admin ou via Bastion.
14. **Pourquoi ne pas exposer le port SQL (1433) à Internet ?** La base contient des données sensibles ; l'exposer en fait une cible (force brute, exfiltration). Accès depuis le subnet web uniquement / Private Endpoint.
15. **Différence règle entrante / sortante ?** Inbound filtre le trafic arrivant vers la ressource ; Outbound filtre le trafic qui en part. Évalués séparément.
16. **Différence Load Balancer / Application Gateway ?** LB = couche 4 (TCP/UDP), simple ; App Gateway = couche 7 (HTTP/HTTPS) avec routage applicatif, terminaison TLS et WAF.
17. **À quoi sert un répartiteur de charge ?** Distribuer le trafic sur plusieurs instances derrière un point d'entrée unique → disponibilité + montée en charge.
18. **Pourquoi une sonde de santé ?** Pour ne router que vers les instances saines : elle retire automatiquement une VM défaillante et la réintègre quand elle répond.
19. **Mesure pour réduire l'impact d'une panne de VM ?** Plusieurs VM derrière un Load Balancer avec sonde (+ multi-zone).
20. **Pourquoi déployer en multi-zone améliore la disponibilité ?** Les zones sont des datacenters physiquement séparés ; une panne locale n'affecte qu'une zone.

#### C. Stockage & base de données

21. **Quel service remplace le stockage local de documents ?** Azure Storage Account (Blob Storage).
22. **Pourquoi le stockage objet plutôt qu'un disque local de VM ?** Durabilité/redondance, découplage des VM, scalabilité, accès partagé, fonctions intégrées (versioning, lifecycle).
23. **Pourquoi éviter un conteneur public par défaut ?** Risque de fuite de données (documents clients, RGPD) ; accès doit être privé/authentifié.
24. **Intérêt du versioning ?** Conserver chaque version d'un blob → restaurer après écrasement/suppression ; couplé au soft-delete.
25. **Pourquoi le versioning peut-il augmenter les coûts ?** Les anciennes versions s'accumulent et sont facturées comme du stockage ; à plafonner via lifecycle policy.
26. **Quel service remplace une base SQL sur serveur ?** Azure SQL Database (PaaS managée).
27. **Avantages d'Azure SQL vs SQL sur VM ?** Pas d'administration OS, sauvegardes automatiques (PITR), HA intégrée, patchs auto, TDE par défaut.

#### D. Identité, gouvernance, tags

28. **Que signifie RBAC ?** *Role-Based Access Control* : attribution de droits par rôle sur un scope.
29. **Principe du moindre privilège ?** N'accorder que les droits strictement nécessaires, le temps nécessaire.
30. **Pourquoi le rôle Owner pour tous est une erreur ?** Droits trop larges → impact majeur en cas d'erreur/compromission. Préférer Reader/Contributor + MFA.
31. **Risque d'un compte administrateur partagé ?** Perte de traçabilité/imputabilité, révocation difficile, droits trop larges.
32. **Pourquoi taguer les ressources ?** Imputer les coûts, identifier le responsable, filtrer, automatiser la gouvernance (FinOps + Policy).
33. **À quoi sert Azure Policy ?** Imposer ou auditer des règles de configuration (ex. refuser une ressource sans tag Owner).

#### E. Terraform / IaC

34. **Terraform est-il impératif ou déclaratif ?** Déclaratif : on décrit l'état final ; Terraform calcule les actions. D'où l'importance du `plan`.
35. **Rôle d'un provider ?** Plugin qui traduit les ressources Terraform en appels à l'API d'une plateforme (azurerm pour Azure).
36. **À quoi sert le state (`tfstate`) ?** Lier le code aux ressources réelles ; source de vérité de ce que Terraform gère.
37. **Pourquoi `plan` avant `apply` ?** Prévisualiser les changements ; une destruction/un remplacement imprévu est un signal d'alerte.
38. **Que signifie le symbole `-/+` dans un plan ?** Ressource à remplacer (destruction puis recréation) → risque d'interruption / perte de données locales.
39. **Pourquoi le state local est-il problématique en équipe ?** Pas de partage/verrouillage, risque de perte, secrets en clair, conflits → backend distant sécurisé.
40. **Qu'est-ce que le drift ?** Écart entre l'infrastructure réelle et le code, créé par une modification manuelle ; détecté au `plan`.
41. **Différence variable / local / output ?** Variable = entrée paramétrable ; local = valeur calculée interne ; output = information exposée après déploiement.
42. **Intérêt de `count` ?** Déployer plusieurs instances identiques sans dupliquer le code.
43. **Intérêt des modules ?** Réutiliser une logique commune (réseau, compute…) sur plusieurs environnements sans duplication.
44. **Pourquoi éviter les secrets dans les fichiers Terraform ?** Risque de compromission ; utiliser Key Vault / variables d'environnement / variables CI sécurisées.
45. **Différence changement Terraform / changement manuel dans le portail ?** Terraform = versionné, relu, tracé via plan/apply (source de vérité) ; manuel = drift, non tracé, peut être annulé.
46. **Comment Terraform contribue au FinOps ?** Ressources visibles, nommées, taguées, destructibles → inventaire et nettoyage facilités.

#### F. Administration (CLI, Bash, Python)

47. **Différence provisionnement / exploitation ?** Le provisionnement crée les ressources ; l'exploitation les administre, surveille et optimise dans le temps.
48. **Pourquoi Azure CLI plutôt que le portail pour une tâche répétitive ?** Commande rejouable, documentable, scriptable, intégrable en pipeline.
49. **À quoi sert `--query` (JMESPath) ?** Filtrer et transformer les sorties JSON.
50. **Format de sortie utile dans un script Bash ?** TSV (`-o tsv`) : extraction directe dans une variable.
51. **Différence `az vm stop` / `az vm deallocate` ?** `stop` arrête l'OS mais la VM reste allouée (compute facturé) ; `deallocate` libère le compute (non facturé).
52. **Rôle de `DefaultAzureCredential` ?** Authentification SDK qui réutilise plusieurs sources (dont `az login`) sans secret en dur.
53. **Différence métrique / log ?** Métrique = valeur numérique dans le temps ; log = événement textuel détaillé.
54. **Qu'est-ce qu'un runbook ?** Procédure d'exploitation documentée (démarrer, arrêter, vérifier la santé…).
55. **Différence IaC / script d'exploitation ?** IaC (déclaratif) construit l'infra ; script (impératif) l'exploite ponctuellement.
56. **Pourquoi journaliser les actions d'un script ?** Traçabilité (qui/quoi/quand), diagnostic, preuve d'audit.

#### G. Monitoring, FinOps, sécurité (TP4)

57. **Différence monitoring / observabilité ?** Le monitoring constate (« ça marche ? ») ; l'observabilité explique (« pourquoi ? »).
58. **Rôle d'un Log Analytics Workspace ?** Centraliser, interroger (KQL) et corréler logs et métriques.
59. **Qu'est-ce qu'un Action Group ?** Définit qui est notifié et comment lors d'une alerte (e-mail, SMS, webhook…).
60. **Pourquoi définir les seuils d'alerte avec prudence ?** Trop bas → fatigue d'alerte (faux positifs ignorés) ; trop haut → détection tardive.
61. **Pourquoi une alerte doit-elle être associée à une procédure ?** Pour être actionnable et réduire le MTTR ; sinon ce n'est que du bruit.
62. **Quel journal trace les modifications sur les ressources Azure ?** L'Activity Log (control-plane).
63. **Différence log technique / log d'activité ?** Technique = fonctionnement de l'app (data-plane) ; activité = opérations de gestion de l'infra (control-plane).
64. **Pourquoi le cloud peut-il coûter plus cher que prévu ?** Dépense à la consommation, ressources facturées à vide/oubliées/surdimensionnées, absence de tags/budget.
65. **Différence coût constaté / prévisionnel ?** Constaté = déjà facturé (historique) ; prévisionnel (forecast) = projection pour anticiper un dépassement.
66. **Réduction vs optimisation des coûts ?** Réduire = baisser la dépense (parfois au détriment du service) ; optimiser = meilleur rapport valeur/coût sans dégrader la valeur métier.
67. **Pourquoi un budget ne remplace pas une gouvernance ?** Il alerte sur un montant mais ne dit pas quelle ressource/qui ; ne bloque pas la dépense ; nécessite tags + organisation.
68. **Modèle de responsabilité partagée ?** Le fournisseur sécurise l'infrastructure physique ; le client reste responsable de la config, des identités, des données et des accès.
69. **Pourquoi le chiffrement ne suffit pas ?** Il ne protège pas d'un accès public, de droits excessifs, d'un port exposé ou d'une absence de logs ; sécurité multi-couches.
70. **Citez deux mesures de sécurité prioritaires.** RBAC + moindre privilège (+ MFA) et NSG restrictifs (+ désactiver les accès publics inutiles).
71. **Trois actions prioritaires avant une mise en production ?** Activer des alertes critiques ; réduire l'exposition + moindre privilège (+ Defender) ; maîtriser les coûts (budget + tags).
72. **Quelle évolution permet d'automatiser le déploiement ?** L'Infrastructure as Code (Terraform / Bicep), idéalement avec un pipeline CI/CD.

---

> ✅ **Cette fiche couvre l'intégralité des notions des TP1 → TP4** : fondamentaux du cloud, modèles de service, réseau, calcul, stockage, bases de données, identité/gouvernance, Infrastructure as Code (Terraform), administration (CLI/Bash/Python), observabilité, FinOps, sécurité, audit, disponibilité et méthodologie. Les définitions encadrées (📌), les pièges (⚠️), les points clés (🧠) et la banque de Q/R (§18.4) sont conçus pour répondre à **tout type de question théorique** en évaluation écrite.

*— Fin de la fiche de synthèse —*
