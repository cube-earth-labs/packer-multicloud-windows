# ---------------------------------------------------------------------------
# ONE build block, TWO clouds.
#
# This is the whole point of the demo: the hardening baseline is written once
# and Packer fans it out across every source listed below. Adding a third
# target (vSphere, GCP) means adding one line here - not forking the baseline.
# ---------------------------------------------------------------------------

build {
  name = "windows-golden-image"

  sources = [
    "source.amazon-ebs.windows",
    "source.azure-arm.windows",
  ]

  # =========================================================================
  # BASELINE - TWO INTERCHANGEABLE PATHS
  #
  # Shift-left baseline. Each step is work that a ticket-driven shop normally
  # does AFTER the VM exists - which is the part an app team cannot self-serve.
  # Done here, once, every VM launched from the image starts done.
  #
  # PATH A - PowerShell  (ACTIVE below)
  #   Runs with nothing installed but Packer. Scripts are echo stubs.
  #
  # PATH B - Ansible     (COMMENTED OUT below)
  #   ../ansible/*.yml - real playbook content, one file per PowerShell script.
  #   This is the path for a shop that already has Ansible content, because the
  #   hardening role plugs in unchanged.
  #
  # To swap: comment out the four `provisioner "powershell"` blocks in Path A,
  # uncomment Path B, and `ansible-galaxy collection install -r
  # ../ansible/requirements.yml` on the machine running Packer.
  #
  # The point of keeping both in the repo: the baseline is the SAME WORK either
  # way, and neither path changes because there are two clouds.
  # =========================================================================

  # ---- PATH A: PowerShell (active) ----------------------------------------

  provisioner "powershell" {
    script = "${path.root}/scripts/01-install-updates.ps1"
  }

  provisioner "powershell" {
    script = "${path.root}/scripts/02-install-agents.ps1"
    environment_vars = [
      "AGENTS=${join(",", var.agents)}",
    ]
  }

  # Prepares for domain join; does NOT join. A sysprepped image must stay
  # domain-agnostic - the join happens at first boot with a per-VM blob.
  provisioner "powershell" {
    script = "${path.root}/scripts/03-domain-join-prep.ps1"
    environment_vars = [
      "AD_DOMAIN=${var.ad_domain}",
    ]
  }

  provisioner "powershell" {
    script = "${path.root}/scripts/04-cis-hardening.ps1"
    environment_vars = [
      "CIS_PROFILE=${var.cis_profile}",
    ]
  }

  # ---- PATH B: Ansible (commented out - uncomment to swap) ----------------
  #
  # Note there is still only ONE of these for BOTH clouds. Packer hands the
  # ansible provisioner whichever host it is currently building, so the same
  # playbooks run against the AWS instance and the Azure VM unmodified.
  #
  # provisioner "ansible" {
  #   playbook_file = "${path.root}/../ansible/site.yml"
  #   user          = build.User
  #
  #   # Required for Windows: Packer's built-in SSH proxy cannot carry WinRM.
  #   use_proxy = false
  #
  #   extra_arguments = [
  #     "-e", "ansible_connection=winrm",
  #     "-e", "ansible_winrm_scheme=https",
  #     "-e", "ansible_port=5986",
  #     "-e", "ansible_winrm_transport=basic",
  #     "-e", "ansible_winrm_server_cert_validation=ignore",
  #     "-e", "ansible_password=${build.Password}",
  #     "-e", "ad_domain=${var.ad_domain}",
  #     "-e", "cis_profile=${var.cis_profile}",
  #   ]
  # }

  # A restart between hardening and validation proves the baseline survives a
  # reboot - the single most common way a golden image quietly regresses.
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
    script = "${path.root}/scripts/05-validate-baseline.ps1"
    environment_vars = [
      "CIS_PROFILE=${var.cis_profile}",
      "AD_DOMAIN=${var.ad_domain}",
    ]
  }

  # ---- PATH B validation (commented out) ----------------------------------
  #
  # Separate from site.yml because it must run AFTER windows-restart. A failed
  # assert here fails the build, so a non-compliant image never reaches the
  # registry in EITHER cloud.
  #
  # provisioner "ansible" {
  #   playbook_file = "${path.root}/../ansible/05-validate-baseline.yml"
  #   user          = build.User
  #   use_proxy     = false
  #
  #   extra_arguments = [
  #     "-e", "ansible_connection=winrm",
  #     "-e", "ansible_winrm_scheme=https",
  #     "-e", "ansible_port=5986",
  #     "-e", "ansible_winrm_transport=basic",
  #     "-e", "ansible_winrm_server_cert_validation=ignore",
  #     "-e", "ansible_password=${build.Password}",
  #     "-e", "ad_domain=${var.ad_domain}",
  #     "-e", "cis_profile=${var.cis_profile}",
  #   ]
  # }

  # -------------------------------------------------------------------------
  # Generalization is the ONLY genuinely cloud-specific step. `only` scopes a
  # provisioner to one source; everything above stayed shared.
  # -------------------------------------------------------------------------

  provisioner "powershell" {
    only   = ["amazon-ebs.windows"]
    script = "${path.root}/scripts/sysprep-aws.ps1"
  }

  provisioner "powershell" {
    only   = ["azure-arm.windows"]
    script = "${path.root}/scripts/sysprep-azure.ps1"
  }

  # -------------------------------------------------------------------------
  # Both artifacts land in ONE HCP Packer version. Terraform then asks the
  # registry "what is current on the production channel?" and gets an AMI ID
  # in AWS and a gallery image ID in Azure from the same fingerprint.
  # -------------------------------------------------------------------------

  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = <<-EOT
      Windows Server 2022 golden image.
      Baseline: ${var.cis_profile}. Agents baked at build time.
      Built in parallel for AWS and Azure from a single template.
    EOT

    bucket_labels = {
      "os"       = "windows-server-2022"
      "baseline" = var.cis_profile
      "owner"    = "platform-automation"
    }

    build_labels = {
      "agents"      = join(",", var.agents)
      "domain-prep" = var.ad_domain
    }
  }

  post-processor "manifest" {
    output     = "${path.root}/manifest.json"
    strip_path = true
  }
}
