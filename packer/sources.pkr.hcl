packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.3"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = ">= 2.1.7"
      source  = "github.com/hashicorp/azure"
    }
    # Required only for the commented-out Ansible path in build.pkr.hcl.
    # Declared here so `packer init` pre-installs it and swapping paths is a
    # comment change, not a new dependency hunt.
    ansible = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  # Applied to every artifact in both clouds so the fleet is queryable by tag.
  common_tags = {
    Name        = var.image_name
    OS          = "WindowsServer2022"
    Baseline    = var.cis_profile
    DomainReady = var.ad_domain
    BuiltBy     = "packer"
    BuildTime   = local.timestamp
  }
}

# ---------------------------------------------------------------------------
# SOURCE 1 - AWS
#
# Windows on AWS needs WinRM stood up by hand via user_data before Packer can
# talk to the instance. That bootstrap file is the ONLY AWS-specific plumbing.
# ---------------------------------------------------------------------------
source "amazon-ebs" "windows" {
  region        = var.aws_region
  instance_type = var.aws_instance_type

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["801119661308"] # Amazon
  }

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "20m"
  user_data_file = "${path.root}/scripts/aws-bootstrap-winrm.txt"

  ami_name        = "${var.image_name}-${local.timestamp}"
  ami_description = "Windows Server 2022 golden image - ${var.cis_profile}"

  tags     = local.common_tags
  run_tags = local.common_tags
}

# ---------------------------------------------------------------------------
# SOURCE 2 - Azure
#
# The azure-arm builder configures WinRM itself when os_type = "Windows", so
# there is no bootstrap file on this side. Same provisioners, less plumbing.
# ---------------------------------------------------------------------------
source "azure-arm" "windows" {
  subscription_id = var.azure_subscription_id
  location        = var.azure_location
  vm_size         = var.azure_vm_size

  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-datacenter-azure-edition"

  communicator   = "winrm"
  winrm_username = "packer"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "20m"

  managed_image_name                = "${var.image_name}-${local.timestamp}"
  managed_image_resource_group_name = var.azure_resource_group

  shared_image_gallery_destination {
    resource_group       = var.azure_resource_group
    gallery_name         = var.azure_gallery_name
    image_name           = var.image_name
    image_version        = var.image_version
    replication_regions  = [var.azure_location]
    storage_account_type = "Standard_LRS"
  }

  azure_tags = local.common_tags
}
