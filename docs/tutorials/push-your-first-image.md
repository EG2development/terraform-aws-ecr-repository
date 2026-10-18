# Tutorial: push your first image

In this tutorial you create a repository with the module, push an image to it, see
that a second push of the same tag is refused, and remove everything again. It takes
about ten minutes and costs nothing worth measuring.

## Before you start

- Terraform 1.16 or later, Docker, and the AWS CLI with credentials for a sandbox
  account that may manage ECR repositories.
- Read access to this repository.

## 1. Write the configuration

Create an empty directory with a file `main.tf`:

```hcl
terraform {
  required_version = ">= 1.16.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

module "ecr_repository" {
  source = "git::https://github.com/EG2development/terraform-aws-ecr-repository.git?ref=v1.0.0"

  name         = "tutorial/hello"
  force_delete = true # only because this tutorial deletes the repository at the end
}

output "repository_url" {
  value = module.ecr_repository.repository_url
}
```

## 2. Create the repository

```bash
terraform init
terraform apply
```

The plan creates two resources: the repository and its lifecycle policy.

## 3. Push an image

```bash
URL="$(terraform output -raw repository_url)"
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "${URL%%/*}"
docker pull public.ecr.aws/docker/library/hello-world:latest
docker tag public.ecr.aws/docker/library/hello-world:latest "${URL}:v1"
docker push "${URL}:v1"
```

Push the same tag again:

```bash
docker push "${URL}:v1"
```

The push is refused with a "tag invalid" error: tags are immutable, so `v1` will
always mean the image you pushed first.

## 4. See the scan result

```bash
aws ecr describe-image-scan-findings --repository-name tutorial/hello --image-id imageTag=v1 \
  --query 'imageScanStatus.status'
```

The scan ran on push; the status is `COMPLETE` after a minute or so.

## 5. Clean up

```bash
terraform destroy
```

## Next steps

[Customise the repository](../how-to/customise-the-repository.md): different
retention, cross-account pull or your own KMS key.
