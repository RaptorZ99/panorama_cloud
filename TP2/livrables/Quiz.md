# Quiz de validation — TP2 Terraform sur Azure (ShopEasy)

> 20 questions de validation des connaissances (section 21 du TP).

---

**1. Terraform est-il un outil impératif ou déclaratif ? Justifier.**
**Déclaratif.** On décrit l'**état final souhaité** de l'infrastructure ; Terraform calcule lui-même les
actions (créer, modifier, détruire) nécessaires pour l'atteindre. On n'écrit pas la suite d'ordres, mais le
résultat attendu — ce qui explique l'importance du `plan`.

**2. Quel est le rôle d'un provider Terraform ?**
Un provider est un **plugin** qui sait dialoguer avec l'API d'une plateforme et **traduit** les ressources
Terraform en appels concrets. Ici, **`azurerm`** pilote Azure Resource Manager (RG, VNet, VM, etc.).

**3. À quoi sert le fichier `terraform.tfstate` ?**
C'est le **fichier d'état** : il fait le **lien entre le code et les ressources réelles** créées dans Azure.
Sans lui, Terraform ne sait plus précisément quelles ressources il gère.

**4. Pourquoi exécuter `terraform plan` avant `terraform apply` ?**
Pour **prévisualiser** les changements (créations, modifications, destructions) **avant** d'impacter Azure.
C'est un garde-fou : une destruction ou un remplacement imprévu dans le plan est un signal d'alerte.

**5. Quelle commande formate le code Terraform ?**
`terraform fmt`.

**6. Quelle commande vérifie la syntaxe et la cohérence de base ?**
`terraform validate`.

**7. Quel service Azure correspond au réseau privé logique ?**
Le **Virtual Network (VNet)**.

**8. Quel composant Azure filtre les flux réseau entrants et sortants ?**
Le **Network Security Group (NSG)**.

**9. Pourquoi restreindre SSH à une seule adresse IP ?**
Pour **réduire la surface d'attaque** : ouvrir le port 22 à tout Internet l'expose en permanence aux scans
automatisés et aux attaques par **force brute**. En limitant à l'IP de l'administrateur, seule cette adresse
peut tenter une connexion.

**10. Quel est l'intérêt de `count` dans le déploiement des VM ?**
Déployer **plusieurs instances identiques** (ici 2 VM) **sans dupliquer le code** ; `count.index` permet de
nommer et de relier chaque VM à son interface et à son IP.

**11. Pourquoi utiliser des variables ?**
Pour **éviter les valeurs codées en dur** et rendre le projet **paramétrable et réutilisable** (projet,
région, environnement, taille de VM…) sur plusieurs environnements.

**12. Pourquoi utiliser des outputs ?**
Pour **exposer les informations utiles** après déploiement (IP du Load Balancer, IP des VM, nom du Storage)
sans avoir à fouiller le portail, et pour les réutiliser par script ou par un autre module.

**13. Pourquoi taguer les ressources ?**
Pour la **gouvernance** et le **FinOps** : imputer les coûts (par projet, environnement, centre de coût),
filtrer les ressources, identifier le propriétaire et automatiser des politiques.

**14. Quelle est la différence entre un changement Terraform et un changement manuel dans le portail ?**
Un changement **Terraform** est **versionné, relu, tracé** et passe par `plan` puis `apply` (le code reste la
source de vérité). Un changement **manuel** dans le portail se fait **hors code** : il crée une **dérive**
(*drift*), n'est pas tracé, et sera détecté — voire annulé — au prochain `plan`.

**15. Quel risque présente un Storage Account public ?**
Une **fuite de données** : les blobs (documents métier, factures) deviennent accessibles à **quiconque
connaît l'URL**, avec un risque de non-conformité (RGPD).

**16. Pourquoi le versioning Blob peut-il générer des coûts supplémentaires ?**
Parce qu'il **conserve une copie de chaque version** d'un objet à chaque modification. Ces versions
**s'accumulent** et sont **facturées comme du stockage** ; sans règle de cycle de vie, elles ne sont jamais
purgées.

**17. À quoi sert un Load Balancer ?**
À **répartir le trafic** entrant sur plusieurs VM derrière un **point d'entrée unique**, ce qui améliore la
**disponibilité** et permet de **monter en charge**. Couplé à une sonde de santé, il retire automatiquement
une VM défaillante de la rotation.

**18. Pourquoi un state distant est-il préférable en équipe ?**
Il offre un **emplacement central partagé** (même état pour tous + CI/CD), un **verrouillage** (pas de
corruption en cas d'`apply` simultané), supprime le state des postes (pas de perte ni de commit accidentel)
et s'intègre dans un pipeline.

**19. Citer deux bonnes pratiques de sécurité pour un projet Terraform.**
- **Ne jamais versionner de secret** : `terraform.tfvars` et `terraform.tfstate` exclus du dépôt (le state
  contient des secrets en clair), secrets dans **Key Vault** / variables CI sécurisées.
- **Moindre privilège** : SSH restreint à l'IP admin, NSG limitant les ouvertures, droits limités de
  l'identité qui exécute Terraform, **backend de state distant sécurisé** (RBAC, chiffrement).

**20. Citer deux améliorations possibles pour rendre l'architecture plus proche d'un environnement de production.**
- Supprimer les **IP publiques des VM** et administrer via **Azure Bastion** ; externaliser le **state** dans
  un backend Azure sécurisé.
- Ajouter un **Application Gateway + WAF** (HTTPS), de la **supervision** (Azure Monitor / Log Analytics) et
  une **pipeline CI/CD** (`fmt`/`validate`/`plan` + approbation).
