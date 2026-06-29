# Atelier 9 — Plan d'amélioration avant production : note de recommandations DSI (ShopEasy)

> **Objectif :** transformer les constats techniques du TP4 en **recommandations de décision** pour la DSI. \
> **Livrable attendu :** une note de recommandations DSI claire, argumentée et exploitable.
>
> **Destinataire :** Direction des Systèmes d'Information — **Auteurs :** Louis SCARFONE & Maxence BOURRAGUE.

---

## 1. Contexte et objectif

ShopEasy a migré son application de gestion de commandes vers Azure (conception au TP1, industrialisation Terraform au TP2, administration au TP3). Le TP4 fait passer l'environnement d'une logique de **construction** à une logique d'**exploitation** : superviser, alerter, maîtriser les coûts, sécuriser et auditer. Cette note synthétise les constats et propose un **plan d'amélioration priorisé avant toute mise en production**.

---

## 2. État actuel de l'exploitation

L'environnement (`rg-shopeasy-dev`, `swedencentral`) comprend un réseau segmenté, **deux VM web** (`B2ats_v2`, Nginx) derrière un **Load Balancer** Standard, et un **Storage** privé. La supervision a été initialisée : **Log Analytics `law-shopeasy-dev`** créé, **Activity Log et Storage raccordés**, **2 alertes** actives et un **action group** de notification. Le socle est **sain mais incomplet** : déploiement **mono-zone**, base de données **non déployée**, logs invité/applicatifs **non centralisés**, posture Defender **non activée**.

---

## 3. Alertes et monitoring proposés

- **En place :** workspace centralisé, alertes **CPU > 70 %** (Moyenne) et **VM indisponible** (Haute) notifiées à `ag-shopeasy-ops`.
- **À compléter :** **sonde de disponibilité synthétique** (URL ping test sur l'IP du Load Balancer) pour mesurer la disponibilité **réelle vue par l'utilisateur** ; **logs Nginx/HTTP** centralisés (Azure Monitor Agent → workspace) pour diagnostiquer les incidents **applicatifs** ; alertes **disque/mémoire** (RAM contrainte à 1 Gio) et **crédits CPU** (burstable) ; enrichissement du **tableau de bord** d'exploitation `ShopEasy-Exploitation` (créé à l'Atelier 5).

---

## 4. Analyse FinOps

Coût **≈ 47 $/mois en 24/7** (prix réels Azure Retail Prices), dont **~92 %** sur **Load Balancer + compute + IP publiques** — le LB et les IP facturent **même à trafic nul**. Environnement **propre** (aucun disque/IP orphelin), mais **14 ressources sans tag `Application`** et **aucun budget actif**. Leviers : **désallouer les VM** hors usage (et détruire entre séances → ≈ 0), **supprimer les IP des VM** (via Bastion), **généraliser les tags** (Azure Policy), **créer un budget** 50 $ avec alertes 80 %/100 %.

---

## 5. Analyse sécurité

**Contrôles en place :** SSH **restreint à l'IP admin** (jamais `0.0.0.0/0`), stockage **chiffré (TLS 1.2, HTTPS-only) et privé**, **logs d'activité disponibles**, aucun secret versionné. **Risques identifiés :** **accès public du Storage autorisé** (`allowBlobPublicAccess=true`, défaut Terraform), **2 IP publiques directes sur les VM**, **droits `Owner` larges** (compte unique), **Microsoft Defender non activé** (CSPM/servers/storage) et **mises à jour système non vérifiées** (recommandations Advisor réelles).

---

## 6. Risques résiduels

- **Disponibilité :** déploiement **mono-zone** (pas d'Availability Zones sur *Azure for Students*) et **base de données absente** → pas de SLA élevé tenable en l'état.
- **Observabilité :** logs **invité/applicatifs** non centralisés → diagnostic applicatif limité.
- **Sécurité :** posture **Defender non activée**, exposition réseau (IP de VM, storage public) à corriger.
- **Coûts :** **budget non créé** (création CLI bloquée) → dérive non détectée tant qu'il n'est pas posé via Cost Management.

---

## 7. Plan d'action priorisé

| Action | Priorité | Responsable | Gain attendu |
|---|---|---|---|
| **Compléter les alertes critiques** (sonde de disponibilité, disque/mémoire) | **Haute** | Équipe Cloud | Détection d'incident côté utilisateur |
| **Réduire l'exposition réseau** : désactiver l'accès public du Storage + supprimer les IP des VM (Bastion) | **Haute** | Sécurité / Ops | Réduction de la surface d'attaque |
| **Activer Microsoft Defender for Cloud** (CSPM, servers, storage) | **Haute** | Sécurité | Posture et détection des menaces |
| **Appliquer le moindre privilège** (RBAC : `Reader`/`Contributor`, MFA) | **Haute** | Sécurité | Limiter l'impact d'une compromission |
| **Généraliser les tags obligatoires** (Azure Policy) | Moyenne | Équipe projet | Pilotage et imputation des coûts |
| **Créer le budget Azure** (50 $/mois, alertes 80 %/100 %) | Moyenne | FinOps | Contrôle des dépenses |
| **Centraliser les logs applicatifs** (Azure Monitor Agent → workspace) | Moyenne | Ops | Diagnostic applicatif |
| **Enrichir le tableau de bord DSI** (`ShopEasy-Exploitation`, Atelier 5) | Moyenne | Ops | Suivi opérationnel |
| **Évoluer vers le multi-zone + base managée HA** | Basse | Architecture | Disponibilité de production |

---

## 8. Conclusion

L'environnement ShopEasy dispose d'une **base technique exploitable** — supervision initialisée, coûts chiffrés, sécurité partiellement maîtrisée, changements auditables — **mais il doit être renforcé avant toute mise en production**. Les priorités sont la **mise en place d'alertes critiques complètes**, la **réduction de l'exposition réseau** (accès public du Storage, IP des VM), l'**application du moindre privilège** et de **Microsoft Defender**, puis la **création d'un budget** et la **formalisation d'un tableau de bord**. Ces actions réduisent le **risque opérationnel**, améliorent la **visibilité de la DSI** et **maîtrisent les coûts cloud**, en s'appuyant sur les quatre piliers d'une plateforme mature : **observabilité, FinOps, sécurité et gouvernance**.

---

## ✅ État après l'Atelier 9

- Note de recommandations DSI complète en **8 sections** (contexte, état, monitoring, FinOps, sécurité, risques résiduels, plan d'action, conclusion).
- **Plan d'action priorisé** (9 actions : Priorité / Responsable / Gain attendu) couvrant les axes du TP.
- Synthèse argumentée des Ateliers 1 à 8, exploitable par une équipe technique **et** par la DSI.

> Atelier de **synthèse** : le livrable est cette note (1–2 pages). **Aucune capture attendue.**

**Fin du TP4 — l'ensemble des 9 ateliers est réalisé.**
