variable "region" {
  type        = string
  default     = "westus2"
  description = "The Azure region where the resources should be deployed to."
}

variable "prefix" {
  type    = string
  default = "stackrox-sentinel"
}
