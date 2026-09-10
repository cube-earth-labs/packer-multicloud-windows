# Demo defaults. Override per environment with -var-file or PKR_VAR_* env vars.
image_name    = "win2022-golden"
image_version = "0.0.1"

hcp_bucket_name = "windows-server-2022-golden"

aws_region        = "us-east-1"
aws_instance_type = "t3.large"

azure_location       = "centralus"
azure_vm_size        = "Standard_D2s_v5"
azure_resource_group = "rg-golden-images"
azure_gallery_name   = "sig_golden_images"

ad_domain   = "corp.example.com"
cis_profile = "CIS-Windows-Server-2022-L1"
