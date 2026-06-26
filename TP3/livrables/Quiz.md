# Quiz final — TP3 Administration & Automatisation Azure (ShopEasy)

> 20 questions de validation des connaissances (section 18 de l'énoncé).

---

**1. Quelle est la différence entre `az vm stop` et `az vm deallocate` ?**
`az vm stop` arrête le système d'exploitation mais la VM **reste allouée** sur l'hôte : le **compute continue d'être facturé**. `az vm deallocate` arrête **et libère** les ressources de calcul (état *Stopped (deallocated)*) : le compute **n'est plus facturé** (seuls le disque OS et l'IP statique restent). En développement, c'est `deallocate` qu'il faut privilégier.

**2. Pourquoi est-il préférable d'utiliser Azure CLI plutôt que le portail pour une tâche répétitive ?**
Une commande CLI est **rejouable à l'identique**, **documentable**, **intégrable à un script** et exécutable dans un **pipeline**. Le portail est manuel, peu reproductible, difficile à tracer et source d'erreurs.

**3. À quoi sert l'option `--query` dans Azure CLI ?**
À **filtrer et transformer** les sorties JSON avec le langage **JMESPath** : sélectionner des champs, filtrer des éléments, renommer des colonnes. Exemple : `--query "[?powerState=='VM running'].name"`.

**4. Quel format de sortie est utile pour réutiliser un résultat dans un script Bash ?**
Le **TSV** (`-o tsv`) : sans guillemets ni en-tête, il s'extrait directement dans une variable (`VM_ID=$(az vm show ... -o tsv)`).

**5. Pourquoi les tags sont-ils importants pour le FinOps ?**
Ils permettent de **ventiler la facture** (par application, environnement, **centre de coût**), d'identifier le **responsable** (`Owner`) et d'automatiser des politiques (arrêt des ressources `dev`). Sans tags, impossible d'imputer ou d'optimiser les coûts.

**6. Qu'est-ce qu'un runbook d'exploitation ?**
Une **procédure documentée** décrivant comment réaliser une action de façon fiable : démarrer/arrêter un environnement, vérifier la santé d'un service, réagir à une alerte. Les scripts du TP3 (`inventory.sh`, `vm-power.sh`, `healthcheck.sh`) forment un mini-runbook.

**7. Pourquoi faut-il éviter d'ouvrir SSH à tout Internet ?**
Exposer le port 22 à `0.0.0.0/0` l'expose en permanence aux **scans automatisés** et aux attaques par **force brute**. On restreint l'accès à l'**IP de l'administrateur** (`/32`) pour réduire la surface d'attaque.

**8. Quelle commande permet de lister les ressources d'un groupe de ressources ?**
`az resource list --resource-group <rg>` (avec `--output table` ou `json`).

**9. Quel service Azure permet de suivre les métriques et de créer des alertes ?**
**Azure Monitor** (métriques, logs, alertes métriques et action groups).

**10. Quelle est la différence entre métrique et log ?**
Une **métrique** est une valeur **numérique** échantillonnée dans le temps (CPU %, débit réseau). Un **log** est un **événement détaillé** (texte structuré) produit par une ressource ou une application. La métrique **mesure**, le log **raconte**.

**11. Pourquoi faut-il versionner les scripts d'exploitation ?**
Pour **tracer les modifications**, pouvoir **revenir en arrière**, **collaborer** (revue de code) et garantir que tous utilisent la **même version fiable**. Un script d'exploitation est du **code**.

**12. Quel est le rôle de `DefaultAzureCredential` dans un script Python Azure ?**
C'est une **chaîne d'authentification** qui tente successivement plusieurs sources (variables d'environnement, identité managée, session `az login`…) pour obtenir un **token Azure AD** **sans coder de secret**. Dans notre `inventory.py`, elle réutilise la session `az login`.

**13. Pourquoi faut-il tester un script sur un environnement non productif ?**
Un script d'administration peut **arrêter, modifier ou supprimer** des ressources. Le tester en **dev** évite d'impacter la production en cas de bug, de mauvaise variable ou d'action destructive imprévue.

**14. Citer deux risques liés à un script d'administration mal sécurisé.**
- **Action destructive sans confirmation** : arrêt/suppression accidentelle de ressources (surtout en production).
- **Secrets en clair** dans le code (clé, mot de passe) exposés en cas de fuite ou de versionnement.
*(Autres : droits trop larges, absence de journalisation.)*

**15. Quelle information doit figurer dans un rapport d'exploitation ?**
Inventaire des ressources, état des VM/services, contrôle des **tags/gouvernance**, **sécurité**, **supervision**, **analyse des coûts**, **risques** et **recommandations priorisées** — le tout compréhensible par l'équipe technique **et** la DSI.

**16. Pourquoi un budget Azure ne remplace-t-il pas une gouvernance des ressources ?**
Un budget **alerte sur un montant** mais ne dit **pas** quelles ressources sont concernées, qui en est responsable, ni lesquelles peuvent être arrêtées. Sans **tags** et **organisation**, on voit la dérive sans pouvoir agir précisément ; de plus, le budget **ne bloque pas** la dépense.

**17. Citer deux actions simples pour réduire les coûts d'un environnement de développement.**
- **Désallouer les VM** hors usage (et détruire l'environnement entre les séances).
- **Supprimer les ressources orphelines / IP publiques inutilisées** (ou réduire la taille des VM).

**18. Pourquoi faut-il journaliser les actions d'un script ?**
Pour **tracer** qui a fait quoi et quand (**audit**), **diagnostiquer** en cas d'incident et **prouver** les contrôles effectués. Notre `vm-power.sh` écrit chaque action horodatée dans `logs/vm-power.log`.

**19. Quelle différence faites-vous entre IaC et script d'exploitation ?**
L'**IaC** (Terraform) décrit l'**état cible** de l'infrastructure de manière **déclarative** : elle **construit et fait évoluer** l'infra. Un **script d'exploitation** (Bash/Python) réalise des **actions ponctuelles** sur l'existant (inventaire, arrêt, contrôle de santé) de manière **impérative** : il **exploite** l'infra. L'un construit, l'autre administre.

**20. Citer trois contrôles que vous intégreriez dans un `healthcheck.sh`.**
- Existence du **groupe de ressources** (bloquant).
- Présence et **état des VM**.
- **Ressources sans tag** obligatoire (`Application` / `Owner`).
*(Également implémentés : au moins une alerte Azure Monitor, existence du Storage Account et du conteneur `operations`, règle NSG autorisant HTTP/HTTPS.)*
