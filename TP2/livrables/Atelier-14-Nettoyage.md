# Atelier 14 — Nettoyage de l'environnement (ShopEasy)

> **Objectif :** supprimer proprement toutes les ressources créées pour arrêter la facturation. \
> **Livrable attendu :** prévisualisation de la destruction + commande `terraform destroy`.

> ✅ **Statut : destruction exécutée.** Après validation de l'ensemble des livrables et des captures, la
> destruction effective a été lancée (`terraform destroy`). Les **21 ressources ont été supprimées** et le
> Resource Group n'existe plus côté Azure — la **facturation est arrêtée** (cf. §4).

---

## 1. Pourquoi détruire l'environnement ?

L'infrastructure de test coûte ≈ **46,5 $/mois en 24/7** (cf. Atelier 13), facturée **même à trafic nul**
pour le Load Balancer et les IP publiques. Comme tout est décrit en **Infrastructure as Code**,
l'environnement est **reproductible à l'identique** par `terraform apply` : il n'y a donc aucune raison de le
laisser tourner entre deux séances. La destruction ramène le coût à **≈ 0**.

---

## 2. Prévisualisation — `terraform plan -destroy`

Cette commande **ne supprime rien** : elle liste ce qui *serait* détruit.

```bash
terraform plan -destroy
```

```text
azurerm_lb.web will be destroyed
azurerm_lb_backend_address_pool.web will be destroyed
azurerm_lb_probe.http will be destroyed
azurerm_lb_rule.http will be destroyed
azurerm_linux_virtual_machine.web[0] will be destroyed
azurerm_linux_virtual_machine.web[1] will be destroyed
azurerm_network_interface.web[0] will be destroyed
azurerm_network_interface.web[1] will be destroyed
azurerm_network_interface_backend_address_pool_association.web[0] will be destroyed
azurerm_network_interface_backend_address_pool_association.web[1] will be destroyed
azurerm_network_security_group.web will be destroyed
azurerm_public_ip.lb will be destroyed
azurerm_public_ip.web[0] will be destroyed
azurerm_public_ip.web[1] will be destroyed
azurerm_resource_group.main will be destroyed
azurerm_storage_account.docs will be destroyed
azurerm_storage_container.documents will be destroyed
azurerm_subnet.web will be destroyed
azurerm_subnet_network_security_group_association.web will be destroyed
azurerm_virtual_network.main will be destroyed
random_string.suffix will be destroyed

Plan: 0 to add, 0 to change, 21 to destroy.
```

Les **21 ressources** gérées par Terraform sont prévues pour suppression — le symbole de destruction (`-`)
porte sur l'intégralité du projet.

---

## 3. Commande de destruction

```bash
terraform destroy
```

`terraform destroy` supprime **toutes les ressources gérées par le state**, dans l'ordre inverse des
dépendances (les VM avant le réseau, etc.). En usage interactif, Terraform affiche le plan de destruction et
demande une confirmation (`yes`). La suppression du **Resource Group** entraîne celle de **toutes** les
ressources qu'il contient, y compris les **disques managés** et le **state des objets** côté Azure.

> Le fichier `terraform.tfstate` local est conservé (il reflète alors un projet vide). Les captures d'écran
> ayant déjà été récupérées, la suppression côté Azure n'entraîne aucune perte pour le rendu.

---

## 4. Exécution finale et vérification

Après validation de tous les livrables et captures, la destruction a été exécutée :

```bash
terraform destroy -auto-approve
```

Sortie réelle (extrait, identifiant d'abonnement masqué) :

```text
random_string.suffix: Destruction complete after 0s
azurerm_lb_rule.http: Destruction complete after 4s
azurerm_network_security_group.web: Destruction complete after 11s
azurerm_lb.web: Destruction complete after 10s
azurerm_linux_virtual_machine.web[0]: Destruction complete after 32s
azurerm_linux_virtual_machine.web[1]: Destruction complete after 32s
azurerm_public_ip.lb: Destruction complete after 11s
azurerm_network_interface.web[0]: Destruction complete after 11s
azurerm_network_interface.web[1]: Destruction complete after 22s
azurerm_public_ip.web[0]: Destruction complete after 11s
azurerm_public_ip.web[1]: Destruction complete after 11s
azurerm_subnet.web: Destruction complete after 11s
azurerm_virtual_network.main: Destruction complete after 11s
azurerm_resource_group.main: Destruction complete after 21s

Destroy complete! Resources: 21 destroyed.
```

Vérifications après destruction :

```text
$ terraform state list
(vide — aucune ressource gérée)

$ az group show -n rg-shopeasy-dev
ERROR: (ResourceGroupNotFound) Resource group 'rg-shopeasy-dev' could not be found.
```

> **Point obligatoire du TP** : ne jamais terminer sans avoir supprimé les ressources de formation. C'est
> fait — les **21 ressources sont détruites**, le Resource Group n'existe plus, la **facturation est arrêtée**.

---

## ✅ État après l'Atelier 14

- `terraform destroy` exécuté : **`Destroy complete! Resources: 21 destroyed`**.
- État Terraform **vide** ; Resource Group `rg-shopeasy-dev` **absent** de l'abonnement (`ResourceGroupNotFound`).
- **Facturation arrêtée** (coût ramené à ≈ 0). L'environnement reste **reproductible à l'identique** par `terraform apply`.
- **Fin du TP2** : projet Terraform complet — déployé, validé, documenté et nettoyé.
