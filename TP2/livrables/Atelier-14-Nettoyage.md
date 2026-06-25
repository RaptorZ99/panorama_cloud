# Atelier 14 — Nettoyage de l'environnement (ShopEasy)

> **Objectif :** supprimer proprement toutes les ressources créées pour arrêter la facturation. \
> **Livrable attendu :** prévisualisation de la destruction + commande `terraform destroy`.

> ⚠️ **Statut : destruction NON exécutée à ce stade.** Conformément à la consigne, l'environnement est
> **conservé** le temps de valider l'ensemble des livrables et des captures. Seule la **prévisualisation**
> (`terraform plan -destroy`, qui ne supprime rien) a été exécutée. La destruction effective est la
> **dernière action** du projet (cf. §4).

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

La destruction sera lancée **en toute fin de projet**, une fois tous les livrables et captures validés :

```bash
terraform destroy            # confirmation : yes
```

Vérifications attendues après destruction :

```bash
terraform state list         # (vide)
az group show -n rg-shopeasy-dev   # ResourceGroupNotFound
az group list -o table       # rg-shopeasy-dev absent
```

> **Point obligatoire du TP** : ne jamais terminer sans avoir supprimé les ressources de formation. Cette
> étape sera donc exécutée juste avant la clôture, et ce livrable mis à jour avec la sortie réelle de
> `terraform destroy` (*« Destroy complete! Resources: 21 destroyed »*) et la confirmation de disparition du
> Resource Group.

---

## ✅ État après l'Atelier 14 (préparation)

- Prévisualisation `terraform plan -destroy` : **21 ressources** prêtes à être détruites, `0 add, 0 change`.
- Procédure de destruction documentée (`terraform destroy` + vérifications).
- **Environnement volontairement conservé** pour validation finale ; destruction = dernière action du projet.

**Reste à produire : la note technique (synthèse des choix) et, optionnellement, le quiz de validation.**
