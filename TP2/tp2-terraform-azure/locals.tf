# ============================================================
#  locals.tf — Valeurs calculées réutilisables
# ============================================================

locals {
  # Préfixe de nommage commun à toutes les ressources : "shopeasy-dev"
  prefix = "${var.project}-${var.environment}"

  # Tags de gouvernance appliqués à chaque ressource
  common_tags = {
    project     = var.project
    environment = var.environment
    owner       = "formation"
    managed_by  = "terraform"
    cost_center = "cloud-training"
  }
}
