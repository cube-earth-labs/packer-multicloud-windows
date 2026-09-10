# Packer: Multicloud Windows Golden Image

A single Packer template that builds a **Windows Server 2022** golden image for **AWS and Azure in parallel**, pushes both artifacts into one HCP Packer version, and resolves them in Terraform from a single fingerprint.

The baseline ships twice, as **PowerShell scripts** and as **Ansible playbooks**, so you can adopt whichever your team already maintains.

> [!IMPORTANT]
> **This is an example to work from, not a production image pipeline.**
>
> The baseline steps are deliberately shallow: the five `.ps1` scripts are `Write-Host` stubs, and the Ansible playbooks are illustrative rather than tested against a real estate. The **structure** is the deliverable: replace the hardening, agent, and patching content with your own before using any of it. Nothing here has been security-reviewed, and the placeholder values (`corp.example.com`, `rg-golden-images`, `sig_golden_images`) are not meant to survive contact with a real environment.

## Contents

```
packer/
  sources.pkr.hcl      amazon-ebs + azure-arm sources for Windows Server 2022
  build.pkr.hcl        one build block covering both sources, HCP Packer registry
  variables.pkr.hcl    inputs (regions, sizes, domain, benchmark, agent list)
  values.auto.pkrvars.hcl
  scripts/             Path A - PowerShell baseline
ansible/
  site.yml             Path B - Ansible baseline, same five steps
  01..05-*.yml         one playbook per PowerShell script
  group_vars/all.yml
  requirements.yml     ansible.windows, community.windows
terraform/
  main.tf              hcp_packer_version + hcp_packer_artifact lookups
  outputs.tf           AMI ID and Shared Image Gallery ID
.github/workflows/
  build-windows-golden-image.yml   validate -> build -> gated channel promotion
```

## What it does

**Builds once, for two clouds.** `build.pkr.hcl` lists both sources and every provisioner is written once. Adding vSphere or GCP is one more line in `sources`.

**Isolates the cloud-specific parts.** Only two steps differ, scoped with `only`:

| | AWS | Azure |
| --- | --- | --- |
| WinRM bootstrap | manual, via `user_data_file` | automatic, handled by the builder |
| Generalize | `EC2Launch.exe sysprep` | `Sysprep.exe /generalize` + registry poll |

**Prepares for domain join without joining.** A sysprepped image that was domain-joined at build time carries one machine account every clone then fights over. Step 03 stages an offline `djoin` blob consumed at first boot; step 05 asserts the image is *not* joined.

**Gates on reboot survival.** `windows-restart` sits between hardening and validation, so step 05 runs against a rebooted machine. A failed check fails the build, and the image never reaches the registry.

**Catalogues both artifacts under one fingerprint.** Terraform resolves the `production` channel once and gets an AMI ID and a Gallery image ID that are provably the same build.

### Two baseline paths

`build.pkr.hcl` runs **Path A (PowerShell)** by default, so the repo works with nothing installed but Packer. **Path B (Ansible)** sits beneath it, commented out. The `ansible` plugin is declared in `sources.pkr.hcl`, so `packer init` pre-installs it and swapping is a comment change.

There is one `ansible` provisioner for both clouds. Packer hands it whichever host it is building, so the playbooks are cloud-agnostic.

## Scope

This repo **builds and catalogues** images. It does not deploy them or run a service on them; `terraform/` resolves the registry and outputs two image IDs. For a worked example that ends with running instances, see the multicloud tutorial linked below.

## Usage

Requires Packer ≥ 1.10, an HCP service principal, AWS credentials, and an Azure service principal with an existing resource group and Shared Image Gallery.

```bash
export HCP_CLIENT_ID=... HCP_CLIENT_SECRET=... HCP_PROJECT_ID=...
export PKR_VAR_azure_subscription_id=...

cd packer
packer init .
packer validate .
packer build .                                                   # both clouds
packer build -only='windows-golden-image.amazon-ebs.windows' .   # one cloud
```

```bash
cd terraform
terraform init && terraform apply    # outputs aws_ami_id and azure_image_id
```

For the Ansible path:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
# comment out Path A and uncomment Path B in packer/build.pkr.hcl
```

## Official documentation

Start here rather than with this repo. These are the maintained, supported references:

**Packer**
- [Packer documentation](https://developer.hashicorp.com/packer/docs)
- [Packer tutorials](https://developer.hashicorp.com/packer/tutorials)
- [Build a Windows image](https://developer.hashicorp.com/packer/tutorials/cloud-production/aws-windows-image)
- [Standardize artifacts across multiple cloud providers](https://developer.hashicorp.com/packer/tutorials/cloud-production/multicloud), the multicloud learn guide ([companion repo](https://github.com/hashicorp-education/learn-packer-multicloud))
- [Ansible provisioner](https://developer.hashicorp.com/packer/integrations/hashicorp/ansible/latest/components/provisioner/ansible)
- [Amazon EBS builder](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs) · [Azure ARM builder](https://developer.hashicorp.com/packer/integrations/hashicorp/azure/latest/components/builder/arm)

**Validated patterns**
- [Packer validated patterns](https://developer.hashicorp.com/validated-patterns/packer), including *Integrate HCP Packer with Red Hat Ansible Automation Platform*, *Use HCP Packer and HCP Terraform to improve base image management*, and *Vulnerability and patch management of infrastructure images with HCP*

**HCP Packer**
- [HCP Packer documentation](https://developer.hashicorp.com/hcp/docs/packer)
- [`hcp_packer_version`](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/data-sources/packer_version) · [`hcp_packer_artifact`](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/data-sources/packer_artifact)
