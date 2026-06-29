# Atelier 1 — Cadrer les indicateurs d'exploitation (ShopEasy)

> **Objectif :** avant de configurer un outil, définir **quoi surveiller** pour ShopEasy — couvrir la disponibilité, la performance, les coûts et la sécurité. \
> **Livrable attendu :** un tableau d'indicateurs **priorisés**, avec un seuil proposé et une justification claire pour chaque indicateur retenu.

Le cadrage s'appuie sur l'environnement réel hérité des TP précédents : Load Balancer `lb-shopeasy-dev-web`, deux VM `Standard_B2ats_v2` (burstable, Ubuntu + Nginx), NSG `nsg-shopeasy-dev-web`, Storage `shopeasydevdocsczvc1s`, le tout en `swedencentral` pour ≈ 47 $/mois.

---

## 1. Tableau des indicateurs priorisés

| Domaine | Indicateur | Seuil proposé | Priorité | Justification |
|---|---|---|---|---|
| **Disponibilité** | Disponibilité des backends du Load Balancer (sonde HTTP) | < 100 % des backends sains sur 5 min | **Haute** | Indicateur le plus proche du client : si une VM ne répond plus à la sonde, le site se dégrade — à détecter avant l'utilisateur. |
| **Disponibilité** | État d'alimentation des VM (`PowerState`) | VM `stopped`/`deallocated` inattendue | Moyenne | Une VM web éteinte hors plan = perte de capacité ou indisponibilité. |
| **Performance** | CPU moyen des VM (`Percentage CPU`) | > 80 % en moyenne sur 5 min | **Haute** | Détecte une saturation calcul soutenue avant dégradation des temps de réponse (seuil bien au-dessus de la baseline au repos). |
| **Performance** | Crédits CPU restants (`CPU Credits Remaining`) | Tendance vers 0 | Moyenne | Spécifique au burstable `B2ats_v2` : crédits épuisés → la VM est bridée même sans saturation apparente. |
| **Coût** | Coût mensuel cumulé vs budget | > 80 % puis 100 % du budget (50 $) | **Haute** | Détecte une dérive budgétaire en cours de mois, à temps pour réagir. |
| **Coût** | Ressources sans tag / orphelines (disques, IP) | > 0 ressource | Moyenne | Coût non imputable ou facturé à vide (LB + IP facturés même sans trafic). |
| **Sécurité** | Ports d'administration exposés à Internet (NSG : 22/3389 depuis `0.0.0.0/0`) | Toute règle source Internet sur 22/3389 | **Haute** | Un port d'administration ouvert = scans et force brute permanents ; vérifie que SSH reste limité à l'IP admin. |
| **Sécurité** | Accès public au Storage / droits `Owner` excessifs | `allowBlobPublicAccess = true` ou trop d'`Owner` | Moyenne | Fuite de documents (RGPD) et non-respect du moindre privilège. |
| **Exploitation** | Nombre d'alertes critiques actives | > 0 alerte critique | **Haute** | Vision immédiate de l'état de santé : combien d'incidents en cours ? |
| **Exploitation** | Couverture monitoring (ressources critiques avec diagnostics/logs) | < 100 % des ressources critiques | Moyenne | Une ressource sans logs est un angle mort : rien à analyser après un incident. |

---

## 2. Questions guidées

**1. Pourquoi ne faut-il pas surveiller uniquement le CPU ?**
Le CPU ne couvre qu'un seul axe (la saturation calcul). Un service peut être défaillant avec un **CPU normal** : VM allumée mais Nginx tombé, Load Balancer mal configuré, disque plein, mémoire saturée, base injoignable, crédits CPU épuisés, coût qui dérive, port exposé. Surveiller uniquement le CPU laisse des angles morts sur la disponibilité, la capacité, le coût et la sécurité. Une VM web au repos affiche d'ailleurs un CPU de l'ordre de **0,3 %** (mesuré à l'Atelier 3) — une valeur « saine » qui ne dirait rien d'un site KO ou d'une facture qui grimpe.

**2. Quels indicateurs permettent de détecter un risque de saturation ?**
Les indicateurs de capacité et de performance : **CPU moyen** soutenu, **crédits CPU restants** (déterminant sur le burstable `B2ats_v2`), **mémoire disponible** basse, **espace disque utilisé** (> 85 %, logs Nginx), **IOPS/débit disque** proche du plafond, et le **nombre de connexions/requêtes**. On surveille la **tendance vers la limite**, pas seulement la valeur instantanée.

**3. Quels indicateurs permettent d'identifier une dérive de coûts ?**
Le **coût cumulé du mois vs budget** (alerte 80 %/100 %), le **coût prévisionnel (forecast)**, le **coût par service/par tag**, les **ressources sans tag** (coût non imputable), les **ressources orphelines** (disques/IP non attachés) et les **ressources facturées à vide** (Load Balancer, IP publiques ≈ 29 $/mois). Sans tags ni budget, la hausse se constate trop tard, sur la facture.

**4. Quels signaux permettent de détecter un problème de sécurité ?**
Les **règles NSG ouvertes** sur Internet (surtout 22/3389), l'**accès public au Storage**, les **attributions de rôle excessives** (`Owner`), les **modifications sensibles dans l'Activity Log** (droits, règles réseau, suppressions), les **recommandations Defender/Advisor** et le **Secure Score**, les **authentifications échouées** (force brute) et l'**absence de logs** sur une ressource critique.

**5. Quelle différence faites-vous entre un incident, une alerte et une recommandation ?**

| Notion | Nature | Exemple ShopEasy |
|---|---|---|
| **Recommandation** | Proposition d'amélioration **priorisée**, préventive | « Restreindre les ports d'administration », « créer un budget ». |
| **Alerte** | Signal **automatique** déclenché par une condition franchie, **actionnable** | « CPU > 80 % depuis 5 min », « VM indisponible ». |
| **Incident** | Événement qui **dégrade ou interrompt** réellement le service | « Le site renvoie des erreurs », « une VM est tombée ». |

La recommandation **réduit la probabilité** d'un incident, l'alerte le **détecte au plus tôt** (et le transforme en action), l'incident est ce que l'on cherche à éviter. Une alerte qui n'appelle aucune action n'est pas une alerte mais une simple information de tableau de bord.

---

## ✅ État après l'Atelier 1

- Tableau d'indicateurs **priorisés** couvrant les 5 domaines (Disponibilité, Performance, Coût, Sécurité, Exploitation), chacun avec seuil et justification ancrés dans l'environnement réel de ShopEasy.
- Réponses aux 5 questions guidées.

> Atelier **conceptuel** : le livrable est ce tableau de cadrage. **Aucune capture d'écran n'est attendue** (aucun outil n'est encore configuré).

**Prêt pour l'Atelier 2 — Préparer l'environnement Azure Monitor.**
