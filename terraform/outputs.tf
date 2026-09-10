output "version_fingerprint" {
  description = "The single build both clouds trace back to."
  value       = data.hcp_packer_version.windows_golden.fingerprint
}

output "aws_ami_id" {
  description = "AMI ID for the current production Windows golden image."
  value       = data.hcp_packer_artifact.windows_aws.external_identifier
}

output "azure_image_id" {
  description = "Shared Image Gallery ID for the same build in Azure."
  value       = data.hcp_packer_artifact.windows_azure.external_identifier
}

output "revoke_at" {
  description = "Non-null once the version is revoked - lets you fail a deploy on a recalled image."
  value       = data.hcp_packer_artifact.windows_aws.revoke_at
}
