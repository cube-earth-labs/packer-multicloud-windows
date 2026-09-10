# ---------------------------------------------------------------------------
# The payoff.
#
# One query to the HCP Packer registry resolves the channel to a single
# fingerprint. That ONE fingerprint then yields an AMI ID in AWS and a Shared
# Image Gallery ID in Azure - provably the same baseline, same build, same
# hardening run, in both clouds.
#
# Promoting a new image to production is a channel update. Terraform sees a new
# fingerprint, the ASG/VMSS rolls, and no VM is ever configured in place.
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.100"
    }
  }
}

# One billable channel lookup, reused by every artifact query below.
data "hcp_packer_version" "windows_golden" {
  bucket_name  = var.hcp_bucket_name
  channel_name = var.hcp_channel_name
}

data "hcp_packer_artifact" "windows_aws" {
  bucket_name         = var.hcp_bucket_name
  version_fingerprint = data.hcp_packer_version.windows_golden.fingerprint
  platform            = "aws"
  region              = var.aws_region

  # Disambiguates when several sources produced artifacts in the same region.
  component_type = "amazon-ebs.windows"
}

data "hcp_packer_artifact" "windows_azure" {
  bucket_name         = var.hcp_bucket_name
  version_fingerprint = data.hcp_packer_version.windows_golden.fingerprint
  platform            = "azure"
  region              = var.azure_location

  component_type = "azure-arm.windows"
}

# ---------------------------------------------------------------------------
# From here you would feed the two identifiers into whatever actually runs the
# workload. Deliberately left as outputs so the demo has no cloud credentials
# and no billable resources.
#
#   AWS   -> aws_launch_template.image_id      -> ASG instance refresh
#   Azure -> azurerm_windows_virtual_machine_scale_set.source_image_id
#
# Why this matters for a self-service platform: the app team never sees Packer,
# never sees a hardening script, and never files a ticket for one. They get an
# image ID from a channel the platform team controls. The guardrail is upstream
# of the request instead of being a review step after it.
# ---------------------------------------------------------------------------
