variable "region" {
  description = "AWS Region to create the repository in."
  type        = string
}

variable "name" {
  description = "Repository name."
  type        = string
  default     = "example/app"
}
