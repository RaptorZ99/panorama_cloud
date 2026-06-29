# Quiz de validation — TP4 Monitoring, FinOps & Sécurité Azure (ShopEasy)

> 20 questions de validation des connaissances (section dédiée de l'énoncé).

---

**1. Quelle différence faites-vous entre monitoring et observabilité ?**
Le **monitoring** surveille des indicateurs **prédéfinis** pour savoir **si** le système fonctionne (ex. CPU > 85 %). L'**observabilité** va plus loin : elle vise à comprendre **pourquoi** un système se comporte d'une certaine façon, à partir des signaux qu'il produit (métriques, logs, traces). Le monitoring **constate**, l'observabilité **explique**.

**2. À quoi sert Azure Monitor ?**
C'est le service **central de supervision** d'Azure : il **collecte, analyse et exploite** les métriques, les logs et les alertes des ressources, et alimente tableaux de bord, requêtes et **alertes actionnables**.

**3. Quel est le rôle d'un Log Analytics Workspace ?**
C'est un **espace centralisé** pour stocker, **interroger (KQL)** et **corréler** les logs et métriques de plusieurs ressources. Il est la base de l'observabilité (ici `law-shopeasy-dev`, qui reçoit l'Activity Log et les diagnostics du Storage).

**4. Pourquoi faut-il définir des seuils d'alerte avec prudence ?**
Un seuil **trop bas** déclenche sur des variations normales → **fatigue d'alerte** (faux positifs, alertes finalement ignorées). Un seuil **trop haut** → **détection tardive** (l'incident est déjà là). Le seuil doit être calé sur la **baseline** et lissé sur une **fenêtre** (ex. 5 min).

**5. Qu'est-ce qu'un Action Group ?**
Il définit **qui est notifié et comment** lorsqu'une alerte se déclenche : e-mail, SMS, webhook, ITSM, canal d'exploitation. Ici `ag-shopeasy-ops` notifie l'équipe par e-mail.

**6. Pourquoi les tags sont-ils importants en FinOps ?**
Ils permettent de **ventiler la facture** (par application, environnement, **centre de coût**), d'identifier le **responsable** (`Owner`) et de définir des **budgets ciblés** ou des automatisations. Sans tags, les coûts sont **non imputables**.

**7. Quel service Azure permet de suivre les coûts ?**
**Azure Cost Management** (analyse des coûts, **budgets**, alertes, **coût prévisionnel**).

**8. Pourquoi une ressource sans tag pose-t-elle un problème ?**
Son coût est **non imputable** (à quelle application/équipe l'attribuer ?), on ignore **qui en est responsable** et si elle peut être arrêtée sans risque → gouvernance et pilotage des coûts impossibles.

**9. Quel risque présente un port SSH ouvert à Internet ?**
Une exposition **permanente** aux **scans automatisés** et aux **attaques par force brute**, pouvant mener à la **compromission** de la VM. On restreint l'accès à l'**IP de l'administrateur** (`/32`) ou via **Azure Bastion**.

**10. Que signifie le principe du moindre privilège ?**
Accorder **uniquement les droits strictement nécessaires** pour accomplir une tâche, afin de **limiter l'impact** d'une erreur, d'un compte compromis ou d'un mauvais usage. On préfère `Reader`/`Contributor` au rôle `Owner`.

**11. Quel journal permet de suivre les modifications réalisées sur les ressources Azure ?**
L'**Activity Log** (journal d'activité, *control-plane*) : il enregistre **qui a fait quoi, quand et avec quel résultat** sur les ressources.

**12. Pourquoi faut-il surveiller les droits RBAC ?**
Des **droits excessifs** (trop d'`Owner`) augmentent l'**impact** d'une erreur ou d'une compromission. Surveiller le RBAC permet de détecter les **écarts au moindre privilège** et les **attributions non légitimes**.

**13. Citez deux exemples de métriques utiles pour une VM.**
**`Percentage CPU`** (saturation calcul) et **`Available Memory Bytes`** (mémoire disponible). *(Aussi : `CPU Credits Remaining` pour les VM burstable, `Network In/Out`, `VmAvailabilityMetric`.)*

**14. Citez deux exemples de recommandations de sécurité.**
**Restreindre les ports d'administration** (SSH/RDP à une IP ou via Bastion) et **désactiver l'accès public du Storage**. *(Aussi : activer Microsoft Defender for Cloud, appliquer le moindre privilège, imposer le MFA.)*

**15. Pourquoi une alerte doit-elle être associée à une procédure d'action ?**
Pour être **actionnable**. Sans **procédure** (runbook : quoi vérifier, qui contacter, quelle action), le destinataire reçoit un signal **sans savoir quoi faire** → perte de temps, alerte ignorée. La procédure **réduit le MTTR** et garantit une réponse cohérente.

**16. Quelle différence faites-vous entre coût constaté et coût prévisionnel ?**
Le **coût constaté** est la dépense **réelle déjà facturée** (historique). Le **coût prévisionnel** (*forecast*) est une **projection** de la dépense à venir (ex. fin de mois) selon la tendance : il permet d'**anticiper un dépassement avant qu'il survienne**.

**17. Pourquoi le chiffrement ne suffit-il pas à lui seul à sécuriser une ressource ?**
Le chiffrement protège les données **au repos et en transit**, mais **pas** contre un **accès public** mal configuré, des **droits excessifs**, un **port exposé** ou l'**absence de logs**. La sécurité est **multi-couches** : réseau, identité, configuration, audit — le chiffrement n'en est qu'une.

**18. Quel est l'intérêt d'un tableau de bord pour une DSI ?**
Offrir une **vue synthétique de pilotage** : le service fonctionne-t-il, coûte-t-il trop cher, est-il sécurisé, que faut-il corriger en priorité ? Il sert à **décider**, pas seulement à afficher des courbes techniques.

**19. Qu'est-ce qu'une dérive de coût cloud ?**
Une **augmentation non maîtrisée** de la dépense, souvent due à des **ressources oubliées, surdimensionnées ou facturées à vide** (Load Balancer, IP) et à l'**absence de budget/tags**. On la découvre généralement **trop tard, sur la facture**.

**20. Donnez trois actions prioritaires avant une mise en production.**
1. **Activer des alertes critiques** (disponibilité du service, CPU, VM indisponible).
2. **Réduire l'exposition et appliquer le moindre privilège** (désactiver l'accès public du Storage, supprimer les IP des VM, RBAC restreint, Defender).
3. **Maîtriser les coûts** (créer un budget avec alertes, généraliser les tags obligatoires).
*(Compléments : centraliser les logs applicatifs, formaliser un tableau de bord, évoluer vers le multi-zone.)*
