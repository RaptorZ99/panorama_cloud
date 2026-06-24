# Quiz de validation — TP1 Azure (ShopEasy)

> 25 questions de validation des notions fondamentales du bloc Cloud.

1. **Quel service Azure permet de créer un réseau privé logique ?**
   → **Azure Virtual Network (VNet)**.

2. **Quel service Azure permet de créer une machine virtuelle ?**
   → **Azure Virtual Machines**.

3. **Quelle est la différence entre une région et une zone de disponibilité ?**
   → Une **région** est une zone **géographique** où sont déployés les services. Une **zone de
   disponibilité (AZ)** est un ensemble de **datacenters physiquement séparés** (alimentation,
   refroidissement, réseau indépendants) **au sein** d'une région, pour la résilience.

4. **À quoi sert un Resource Group ?**
   → À **regrouper des ressources partageant un cycle de vie** afin de les administrer, leur appliquer
   des droits (RBAC), les taguer, suivre leurs coûts et les **supprimer ensemble**.

5. **Pourquoi utiliser plusieurs subnets ?**
   → Pour **séparer les rôles** (web / données / admin) et appliquer des **règles de sécurité
   différentes** par couche (cloisonnement, moindre privilège réseau).

6. **À quoi sert un Network Security Group ?**
   → À **filtrer le trafic réseau** entrant et sortant (par port, protocole, source/destination).

7. **Pourquoi ne faut-il pas ouvrir SSH à tout Internet ?**
   → Pour **réduire la surface d'attaque** : SSH ouvert à tous expose à des **scans et attaques par
   force brute**. On le limite à l'IP admin (ou via Azure Bastion).

8. **Quel service peut remplacer le stockage local de documents ?**
   → **Azure Storage Account** (**Blob Storage**).

9. **Quel service Azure peut remplacer une base SQL installée sur un serveur ?**
   → **Azure SQL Database** (base managée / PaaS).

10. **Pourquoi utiliser un répartiteur de charge ?**
    → Pour **distribuer le trafic** sur plusieurs instances et **réduire l'impact de la panne** d'un
    serveur (suppression du point de défaillance unique applicatif).

11. **Quelle est la différence entre Azure Load Balancer et Application Gateway ?**
    → **Load Balancer** agit en **couche 4 (TCP/UDP)** ; **Application Gateway** agit en **couche 7
    (HTTP/HTTPS)** avec des fonctions applicatives (routage par chemin, terminaison TLS, **WAF**).

12. **Que signifie PaaS ?**
    → **Platform as a Service** (plateforme managée : le fournisseur gère l'OS, le runtime, la
    plateforme ; le client gère le code, les données et la configuration).

13. **Azure SQL Database est-il plutôt IaaS ou PaaS ?**
    → **PaaS**.

14. **Pourquoi utiliser Azure Monitor ?**
    → Pour **collecter les métriques et les logs**, **déclencher des alertes** et obtenir une visibilité
    opérationnelle (détecter et diagnostiquer les incidents).

15. **Que surveiller sur une VM web ?**
    → **CPU**, **mémoire**, **disque**, **disponibilité HTTP**, **erreurs** et **activité réseau**.

16. **Que permet Azure Cost Management ?**
    → **Suivre, analyser et optimiser les coûts** Azure (budgets, alertes, répartition par tags).

17. **Pourquoi taguer les ressources ?**
    → Pour **identifier** le propriétaire, le projet, l'environnement et le centre de coût, et ainsi
    **filtrer, attribuer et analyser** les coûts (et automatiser la gouvernance).

18. **Quel risque pose un compte administrateur partagé ?**
    → **Perte de traçabilité** (impossible de savoir qui a agi) et **droits trop larges** ; révocation
    difficile, audit et conformité compromis.

19. **Pourquoi éviter un Storage Account public par défaut ?**
    → Pour éviter le **risque d'exposition de données sensibles** (fuite de documents clients / RGPD).

20. **Quelle mesure permet de réduire l'impact d'une panne de VM ?**
    → Déployer **plusieurs VM derrière un répartiteur de charge** (avec sonde de santé).

21. **Pourquoi séparer la couche web et la couche données ?**
    → Pour **réduire les mouvements latéraux** en cas de compromission et appliquer la **segmentation**
    (la base n'est joignable que depuis le subnet web).

22. **Quelle information doit apparaître dans une note de recommandations DSI ?**
    → **Architecture, coûts, risques, gains et plan d'action** (contexte, services retenus, limites).

23. **Citez deux optimisations de coût possibles.**
    → **Arrêt/désallocation des VM inutilisées** et **choix de tailles adaptées** (+ tags, budgets,
    réservations si usage stable).

24. **Citez deux mesures de sécurité prioritaires.**
    → **RBAC + moindre privilège (avec MFA)** et **NSG restrictifs** (+ chiffrement, suppression des
    accès publics inutiles).

25. **Quelle évolution permettrait d'automatiser le déploiement de cette architecture ?**
    → **L'Infrastructure as Code** (par exemple **Terraform** ou **Bicep**), idéalement avec un pipeline
    **CI/CD**.
