# Atelier 14 — Analyse de sécurité (ShopEasy)

> **Objectif :** identifier les risques de sécurité et proposer des mesures correctives adaptées à Azure. \
> **Livrable attendu :** matrice de risques + plan d'actions sécurité classé par priorité.

---

## 1. Matrice de risques

| Risque | Impact | Probabilité | Mesure corrective | État dans le TP |
|---|---|---|---|---|
| **SSH ouvert à Internet** | Intrusion, force brute, compromission de VM | Élevée si ouvert à `0.0.0.0/0` | NSG **SSH limité à l'IP admin** ; cible : **Azure Bastion**, pas d'IP publique, MFA | ✅ `nsg-web` : 22 limité à l'IP admin |
| **Compte administrateur partagé** | Perte de **traçabilité**, audit impossible, révocation difficile | Moyenne | **Comptes nominatifs** Entra ID + **RBAC moindre privilège** + **MFA** | ⚠️ À mettre en place (gouvernance) |
| **Stockage public** | **Fuite** de documents clients (RGPD) | Faible (bloqué) | **`allow-blob-public-access=false`** + Private Endpoint + RBAC/SAS limités | ✅ Accès public bloqué au niveau compte |
| **Base de données exposée** | Vol / altération des données métier | Faible (pare-feu fermé) | **0 règle de pare-feu** (deny all) ; cible : **Private Endpoint** + auth Entra ID + auditing | ✅ Aucune IP autorisée |
| **Absence de logs / d'alertes** | Incidents **non détectés**, diagnostic impossible | Moyenne | **Azure Monitor** (métriques + alerte) + **logs d'activité** + Defender for Cloud | ✅ Alerte CPU + logs d'activité |
| **Droits excessifs** (Owner pour tous) | Erreur de manipulation ou compromission **à fort impact** | Moyenne | **RBAC** rôles ciblés (Reader/Contributor), **revue** des droits, **PIM** | ⚠️ À encadrer |
| *(bonus)* **Absence de chiffrement / TLS faible** | Interception, données en clair | Faible | **HTTPS-only + TLS 1.2** (Storage/SQL), chiffrement au repos (TDE/SSE) | ✅ TLS 1.2 imposé, chiffrement activé |

---

## 2. Plan d'actions sécurité (par priorité)

### 🔴 Priorité 1 — Gouvernance des accès (immédiat, faible coût)
- **Comptes nominatifs** Microsoft Entra ID (suppression du compte partagé) + **MFA** généralisé.
- **RBAC au moindre privilège** : limiter `Owner`, attribuer `Reader`/`Contributor` selon le besoin ; **revue périodique**.
- Vérifier les **NSG** : SSH restreint (fait), SQL `1433` joignable **uniquement depuis le subnet web** (fait), aucune ouverture large.

### 🟠 Priorité 2 — Réduction de la surface d'exposition (court terme)
- **Azure Bastion** + **suppression des IP publiques** des VM (administration privée).
- **Private Endpoint** pour Azure SQL et Storage → plus aucun accès depuis Internet.
- **HTTPS obligatoire** côté web + **Application Gateway / WAF** en frontal.

### 🟡 Priorité 3 — Détection, résilience et hygiène (moyen terme)
- **Microsoft Defender for Cloud** + **NSG Flow Logs** + **auditing Azure SQL** + alertes de sécurité.
- **Sauvegardes formalisées** et **tests de restauration** réguliers (RPO/RTO).
- **Suppression des ressources inutiles** (FinOps + réduction de la surface d'attaque) et **Infrastructure as Code** pour des déploiements maîtrisés et reproductibles.

---

## 3. Synthèse

Le modèle est celui de la **responsabilité partagée** : Azure sécurise l'infrastructure, **ShopEasy reste
responsable** de la configuration, des identités, des accès et des données. Les bases sont posées dans le
TP (NSG restrictifs, base et stockage non exposés, TLS/chiffrement, supervision). Les chantiers
prioritaires restants sont **la gouvernance des identités** (comptes nominatifs, MFA, moindre privilège)
et la **réduction de l'exposition** (Bastion, Private Endpoint, WAF).

---

## ✅ État après l'Atelier 14
- Matrice de 6+1 risques (impact, probabilité, mesure, état réel).
- Plan d'actions priorisé P1/P2/P3.
- **Prêt pour l'Atelier 15 — note de recommandations DSI (synthèse finale).**
