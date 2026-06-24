# Atelier 1 — Analyse de l'existant (ShopEasy)

> **Objectif :** identifier les limites de l'architecture actuelle et formuler les premiers besoins techniques. \
> **Livrable attendu :** un tableau d'analyse de l'existant + une liste courte des besoins techniques prioritaires.

---

## Rappel de l'architecture actuelle

ShopEasy héberge une application interne de gestion de commandes (consultation clients, saisie de
commandes, génération de factures, dépôt de documents justificatifs) sur **un unique serveur physique**,
dans les locaux de l'entreprise :

- Un serveur **Ubuntu unique** (mono-serveur).
- **Apache / Nginx** exposant l'application web.
- Application **PHP ou Node.js** installée **localement**.
- Base **MySQL installée sur le même serveur**.
- **Documents clients** stockés dans un **répertoire local**.
- **Sauvegardes manuelles et irrégulières**.
- **Aucun outil centralisé de supervision**.
- Un **compte administrateur partagé** par plusieurs personnes.

---

## 1. Tableau d'analyse de l'existant

| Domaine | Risque / limite identifiée | Impact possible pour l'entreprise |
|---|---|---|
| **Disponibilité** | **Point de défaillance unique (SPOF)** : toute l'application repose sur un seul serveur. | Une panne matérielle/OS rend l'application **totalement indisponible** : plus de prise de commande, plus de facturation. |
| | **Aucune redondance ni répartition de charge** (web + app + base colocalisés). | Aucune tolérance aux pannes ; un incident bloque simultanément les **trois couches** ; pics de charge non absorbés. |
| **Sécurité** | **Compte administrateur partagé** entre plusieurs personnes. | **Perte de traçabilité** (impossible de savoir qui a agi), audit et conformité (RGPD) compromis, révocation difficile. |
| | **Données + documents colocalisés** avec le serveur web, pas de segmentation réseau ni de chiffrement mentionné. | La **compromission du serveur web donne un accès direct** à la base MySQL et aux documents clients → **fuite de données**. |
| **Performance** | **Ressources partagées** (CPU/RAM/disque/IO) entre web, applicatif et base sur une seule machine. | **Contention** des ressources, lenteurs sous charge, dégradation du temps de réponse. |
| | **Pas de scalabilité** : scalabilité verticale limitée, **horizontale impossible**. | Impossible d'absorber la **croissance** ou les **pics** (campagnes) → insatisfaction utilisateurs. |
| **Exploitation** | **Aucune supervision centralisée** (ni métriques, ni logs, ni alertes). | Incidents **détectés tardivement** (souvent par les utilisateurs), diagnostic à l'aveugle, **MTTR élevé**. |
| | **Administration 100 % manuelle**, non automatisée, non reproductible. | Opérations **sujettes aux erreurs humaines**, forte **dépendance aux personnes**, patchs/maintenance à la charge totale de l'entreprise. |
| **Coût** | **Modèle CAPEX** : investissement matériel initial + **surdimensionnement** pour anticiper les pics. | Capital immobilisé, **capacité payée mais inutilisée** la majeure partie du temps. |
| | **Coûts d'exploitation cachés** (maintenance, remplacement matériel, temps humain) **non mesurés ni attribués**. | **Aucune visibilité financière** ni capacité de pilotage / d'optimisation. |
| **Sauvegarde** | **Sauvegardes manuelles et irrégulières**. | **RPO non maîtrisé** : perte de données récentes (commandes, factures) probable en cas d'incident. |
| | **Pas de stratégie de restauration testée**, sauvegardes vraisemblablement **locales** (même serveur/site). | **RTO inconnu** ; un sinistre du serveur/site entraîne une **perte totale** (pas de copie hors-site). |

---

## 2. Réponses aux questions guidées

**1. Que se passe-t-il si le serveur physique tombe en panne ?**
Indisponibilité **totale et immédiate** : l'application web, la base et les documents étant sur la même
machine, aucune bascule n'est possible. L'activité commerciale s'arrête (plus de commandes, de factures,
ni d'accès aux dossiers clients). La reprise dépend du délai de réparation/remplacement matériel et de la
qualité des dernières sauvegardes — donc d'un **RPO et d'un RTO aujourd'hui non maîtrisés**.

**2. Pourquoi la base de données locale représente-t-elle un risque ?**
- **Couplage fort** : base et application se partagent CPU/RAM/disque → contention et SPOF commun.
- **Sécurité** : la compromission du serveur web donne un accès direct aux données.
- **Exploitation** : sauvegardes, haute disponibilité, patchs du moteur SQL entièrement à la charge de l'entreprise.
- **Pas d'isolation réseau** : la base n'est pas placée dans une couche dédiée et protégée.

**3. Quels problèmes pose l'absence de supervision ?**
- Détection **tardive ou nulle** des incidents (on apprend la panne par les utilisateurs).
- Pas de métriques → **diagnostic à l'aveugle**, MTTR élevé.
- Impossible d'**anticiper la saturation** (disque plein, CPU, mémoire).
- Aucune alerte de sécurité (tentatives d'intrusion) ni de coût.
- Pas de base factuelle pour dimensionner ou justifier des évolutions.

**4. Quels risques sont liés à l'utilisation d'un compte administrateur partagé ?**
- **Perte de traçabilité / d'imputabilité** (impossible de savoir qui a fait quoi) → audit et conformité compromis.
- **Non-respect du moindre privilège** : tout le monde dispose de tous les droits.
- **Difficulté de révocation** : le départ d'un collaborateur impose de changer le secret pour tous.
- **Surface d'attaque accrue** : secret partagé plus facilement divulgué, pas de MFA individualisé.

**5. Quels éléments devraient être séparés dans une architecture cloud cible ?**
- Les **couches** : réseau / applicatif (web) / données / stockage documentaire.
- La **segmentation réseau** : subnets distincts (web, data, admin) + filtrage **NSG**.
- La **base de données** → service managé **isolé** (Azure SQL Database), non exposé à Internet.
- Les **documents** → stockage objet dédié (**Storage Account / Blob**), hors du serveur applicatif.
- Les **identités** → comptes **nominatifs** + **RBAC** (fin du compte partagé).
- La **disponibilité** → plusieurs instances applicatives derrière un **répartiteur de charge**.
- La **supervision** → plateforme dédiée (**Azure Monitor**).

---

## 3. Besoins techniques prioritaires (synthèse)

1. **Supprimer le SPOF** : redondance applicative (≥ 2 instances) derrière un **répartiteur de charge**.
2. **Séparer les couches** : segmentation réseau (**VNet + subnets** web/data) et filtrage (**NSG**).
3. **Externaliser et fiabiliser la base** : base **managée** (Azure SQL Database), **non exposée** à Internet.
4. **Externaliser les documents** : stockage objet durable (**Storage Account / Blob**) avec versioning.
5. **Fiabiliser les sauvegardes** : stratégie de sauvegarde **automatisée et testée** (RPO/RTO définis, copie hors-site).
6. **Maîtriser les accès** : identités **nominatives** + **RBAC** (moindre privilège), suppression du compte partagé.
7. **Superviser** : supervision centralisée avec **alertes** (Azure Monitor).
8. **Piloter les coûts** : visibilité et gouvernance via **tags + Cost Management** (passage CAPEX → OPEX maîtrisé).
