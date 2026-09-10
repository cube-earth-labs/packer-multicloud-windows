variable "hcp_bucket_name" {
  type        = string
  default     = "windows-server-2022-golden"
  description = "Must match hcp_bucket_name in the Packer template."
}

variable "hcp_channel_name" {
  type        = string
  default     = "production"
  description = "Channel that gates promotion. Rolling this forward is the deploy."
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "azure_location" {
  type    = string
  default = "centralus"
}
