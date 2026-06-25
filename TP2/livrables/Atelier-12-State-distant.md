# Atelier 12 — Préparation d'un state distant (ShopEasy)

> **Objectif :** comprendre pourquoi et comment externaliser le state Terraform dans un backend distant sécurisé. \
> **Livrable attendu :** structure cible du backend Azure + analyse (cet atelier est une **préparation conceptuelle**, sans migration du state).

---

## 1. Le state local et ses limites

Le projet utilise actuellement un **state local** : un fichier `terraform.tfstate` sur le poste.

```bash
ls -la terraform.tfstate          # 59 639 octets
git check-ignore terraform.tfstate # -> ignoré (non versionné)
terraform state list | wc -l       # 21 ressources suivies
```

Ce state **contient des données sensibles en clair**. Une recherche des **noms** d'attributs sensibles (sans
afficher aucune valeur) le confirme :

```text
clé présente: "admin_password"
clé présente: "primary_access_key"     <- clé d'accès du Storage Account
clé présente: "secret"
```

Le state local est acceptable en découverte individuelle, mais **insuffisant en équipe** :

- **perte** possible du fichier (poste, disque) ;
- **conflits** entre plusieurs administrateurs éditant en parallèle ;
- **pas de verrouillage** → corruption du state en cas d'`apply` simultané ;
- **présence de secrets** → un commit accidentel exposerait clés et mots de passe ;
- **difficile à intégrer** dans une chaîne CI/CD.

Le `.gitignore` empêche déjà sa publication, mais ne résout ni le partage, ni le verrouillage, ni la
protection centralisée.

---

## 2. Structure cible — backend Azure Storage

En contexte professionnel, le state est stocké dans un **backend distant** : sur Azure, un **Storage Account
+ container Blob dédiés**. Le bloc à ajouter dans la configuration Terraform serait :

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstatexxx"
    container_name       = "tfstate"
    key                  = "shopeasy/dev/terraform.tfstate"
  }
}
```

| Champ | Rôle |
|---|---|
| `resource_group_name` | RG dédié au state (séparé des ressources applicatives). |
| `storage_account_name` | Storage Account hébergeant le state (nom globalement unique). |
| `container_name` | Container Blob `tfstate`. |
| `key` | Chemin/nom du blob de state — **inclut l'environnement** (`shopeasy/dev/...`) pour isoler dev/recette/prod. |

Le backend `azurerm` fournit nativement le **verrouillage** (via un *lease* sur le blob) : deux `apply`
simultanés ne peuvent pas corrompre le state.

---

## 3. Prérequis (bootstrap) — ne pas ajouter le bloc à la légère

> ⚠️ Le bloc `backend` ne doit **pas** être ajouté sans avoir créé **au préalable** le Resource Group, le
> Storage Account et le container de state. Dans un vrai projet, cette initialisation (*bootstrap*) est
> réalisée par une **équipe plateforme** ou un **projet Terraform dédié**, puis sécurisée (RBAC, chiffrement,
> restrictions réseau).

La bascule se ferait ensuite avec :

```bash
terraform init -migrate-state
```

Terraform copierait alors le state local vers le backend distant. **Cette migration n'est pas effectuée
ici** : conformément à l'énoncé, l'atelier reste **conceptuel**, et le state du TP demeure local (puis sera
supprimé avec les ressources à l'Atelier 14).

---

## 4. Questions

**1. Pourquoi le state distant facilite-t-il le travail en équipe ?**
Il fournit un **emplacement central et partagé** : tous les membres de l'équipe et la **CI/CD** lisent et
écrivent le **même** state, sans copies divergentes. Il apporte le **verrouillage** (un seul `apply` à la
fois → pas de corruption), supprime le state des postes individuels (**pas de perte ni de commit
accidentel**), et s'intègre proprement dans un **pipeline** automatisé.

**2. Pourquoi faut-il protéger l'accès au Storage Account du state ?**
Parce que le state **contient des secrets en clair** (on l'a constaté : `admin_password`,
`primary_access_key`, `secret`) **et** l'inventaire complet de l'infrastructure. Quiconque accède au Storage
peut donc **lire ces secrets** et cartographier le SI. Il faut : **RBAC restreint** (moindre privilège),
**chiffrement au repos**, **restrictions réseau** (private endpoint / pare-feu), **désactivation de l'accès
public**, **rotation des clés** et **journalisation des accès**.

**3. Pourquoi faut-il séparer le state de développement, recette et production ?**
Pour **isoler les environnements** : une erreur ou une corruption du state **dev** ne doit jamais impacter la
**prod**. La séparation (clé/container distincts, ex. `shopeasy/prod/terraform.tfstate`) permet des **droits
différenciés** (qui peut toucher la prod), évite d'**appliquer par erreur** un changement destiné au dev sur
la prod, et donne à chaque environnement un **cycle de vie indépendant** (créer/détruire sans affecter les
autres).

---

## ✅ État après l'Atelier 12

- Limites du state local démontrées concrètement : fichier local de 21 ressources **contenant des secrets en clair** (`admin_password`, `primary_access_key`, `secret`).
- Structure cible documentée : backend `azurerm` (Storage Account + container `tfstate`, clé par environnement, verrouillage natif).
- Bootstrap et migration (`terraform init -migrate-state`) expliqués — **non appliqués** (atelier conceptuel).
- 3 questions traitées (équipe, protection du Storage de state, séparation des environnements).

**Prêt pour l'Atelier 13 — analyses coût, sécurité et maintenabilité.**
