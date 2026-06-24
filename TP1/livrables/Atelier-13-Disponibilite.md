# Atelier 13 — Analyse de disponibilité (ShopEasy)

> **Objectif :** évaluer la robustesse de l'architecture face à des incidents simples. \
> **Livrable attendu :** tableau d'analyse d'incidents + proposition d'évolution de l'architecture.

---

## 1. Scénarios d'incident

| Scénario | Impact | Utilisateurs touchés | Solution technique |
|---|---|---|---|
| **Une VM web tombe en panne** | La **sonde du Load Balancer** la retire du pool ; le service continue sur l'autre VM (capacité ÷ 2). **Pas d'interruption.** | Aucun en temps normal ; ralentissement possible en cas de pic | **Déjà couvert** (2 VM + LB + sonde). Ajouter une 3ᵉ instance / **autoscale** pour la capacité, **multi-zone** pour la résilience |
| **Le répartiteur de charge est mal configuré** | Sonde/règle/backend pool erronés → trafic mal routé ou **rejeté**, service inaccessible **même si les VM sont saines** | Tous | Vérifier sonde (port/chemin), règle, backend pool ; **IaC** pour une config reproductible ; **alertes** sur la santé du LB ; tester après chaque changement |
| **La base de données devient indisponible** | L'application ne peut plus lire/écrire (commandes, factures) → **erreurs fonctionnelles** malgré un web disponible | Tous (fonctions données) | Niveau de service avec **SLA HA**, **sauvegardes/PITR**, **failover group / géo-réplication** en production, monitoring SQL + alertes |
| **Le Storage Account est mal configuré** | Documents **inaccessibles** (droits/réseau) ou **exposés** (si rendu public) → perte d'accès ou **fuite de données** | Tous (documents) ou exposition externe | **Accès privé** (déjà : public bloqué), **versioning + soft-delete** (déjà), **Private Endpoint** + RBAC en production, alertes |
| **Une zone de disponibilité est indisponible** | Les 2 VM étant **sans zone** (même datacenter potentiel), risque de **perte simultanée** des deux | Tous | **Déploiement multi-zone** des VM + **Load Balancer zone-redundant** ; base et stockage redondés zone/région |

---

## 2. Question de synthèse — l'architecture suffit-elle pour une application critique ?

**Non, pas en l'état.** L'architecture actuelle apporte déjà des **points forts** :
- redondance applicative (2 VM derrière un Load Balancer avec sonde de santé) → plus de SPOF applicatif ;
- **services managés** pour la base (Azure SQL) et les documents (Blob) → administration et durabilité déléguées ;
- segmentation réseau + NSG, supervision de base (métriques + alerte).

Mais pour une **application critique**, plusieurs **limites** subsistent :
- **Pas de multi-zone** : les 2 VM ne sont pas réparties en Availability Zones (déploiement zonal restreint
  sur Azure for Students) → une panne de datacenter peut tout arrêter.
- **Base SQL Basic** : pas de haute disponibilité avancée ni de géo-réplication.
- **Stockage LRS** : redondance locale uniquement (pas zone/région).
- **Aucun test de reprise** (DR) formalisé ; sauvegardes non éprouvées.
- **IP publiques sur les VM** : surface d'exposition inutile.

### Évolutions nécessaires (par priorité)
1. **Résilience multi-zone** : VM réparties sur ≥ 2 zones + Load Balancer **zone-redundant**.
2. **Données hautement disponibles** : niveau SQL avec HA (Standard/Premium ou General Purpose) +
   **failover group** géo + **PITR testé** ; stockage **ZRS/GRS** + **Private Endpoint**.
3. **Sauvegarde & reprise** : politique de sauvegarde formalisée + **tests de restauration réguliers** (DR drills), objectifs **RPO/RTO** définis.
4. **Supervision avancée** : alertes sur la santé du LB, les DTU SQL, la disponibilité HTTP ; Application Insights.
5. **Sécurité & exploitation** : **Application Gateway + WAF**, **Azure Bastion** (suppression des IP publiques des VM), **Infrastructure as Code** (Terraform/Bicep) + pipeline CI/CD pour des déploiements reproductibles.

---

## ✅ État après l'Atelier 13
- 5 scénarios d'incident analysés (impact, utilisateurs, solution).
- Verdict + feuille de route d'évolution pour une cible critique.
- **Prêt pour l'Atelier 14 — analyse de sécurité (matrice de risques).**
