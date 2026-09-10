# ---------------------------------------------------------------------------
# Shared inputs. Everything that differs between clouds is a variable so the
# build block below stays cloud-agnostic.
# ---------------------------------------------------------------------------

variable "image_name" {
  type        = string
  default     = "win2022-golden"
  description = "Base name applied to the AMI and the Azure managed image."
}

variable "image_version" {
  type        = string
  default     = "0.0.1"
  description = "Semantic version stamped into the Azure Shared Image Gallery."
}

# --- HCP Packer registry ---------------------------------------------------

variable "hcp_bucket_name" {
  type        = string
  default     = "windows-server-2022-golden"
  description = "HCP Packer bucket that receives BOTH cloud artifacts as one version."
}

# --- AWS -------------------------------------------------------------------

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_instance_type" {
  type    = string
  default = "t3.large"
}

# --- Azure -----------------------------------------------------------------

variable "azure_subscription_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "azure_location" {
  type    = string
  default = "centralus"
}

variable "azure_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "azure_resource_group" {
  type        = string
  default     = "rg-golden-images"
  description = "Pre-existing resource group that holds the managed image and the gallery."
}

variable "azure_gallery_name" {
  type    = string
  default = "sig_golden_images"
}

# --- Baseline knobs (what the customer would actually tune) ----------------

variable "ad_domain" {
  type        = string
  default     = "corp.example.com"
  description = "Domain the image is PREPARED for. The image is never joined at build time."
}

variable "cis_profile" {
  type        = string
  default     = "CIS-Windows-Server-2022-L1"
  description = "Hardening benchmark the build claims to apply."
}

variable "agents" {
  type        = list(string)
  default     = ["crowdstrike", "splunk-uf", "dynatrace-oneagent", "ssm-agent"]
  description = "Agents baked in at build time instead of installed post-provision."
}
