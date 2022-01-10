# KKP on AutoPilot

This structure includes a fully automated setup of Kubermatic Kubernetes Platform
on top of openstack with integration of Flux v2 for GitOps delivery and SOPS for secrets management.

## Used Components and Tools

 * Terraform - for automated resources provisioning in openstack
 * KubeOne - for k8s master cluster preparation
 * KKP installer - for installing core KKP components on master cluster
 * Flux v2 - for managing k8s resources on master cluster with GitOps
 * SOPS, using Age backend - for safe storage of sensitive setup in GitHub
 * GitHub Actions - for the fully fledged delivery pipeline, 0 steps are done manually
   (except the `git init`, `git commit` and `git push`!)

## Preparation
### Create GitHub repository

Create new repository on GitHub [manually](https://docs.github.com/en/get-started/quickstart/create-a-repo)
or using [GitHub CLI](https://cli.github.com/manual/gh_repo_create).

Also prepare an Access token for GitHub which will be used for GitOps setup.

### Get your openstack credentials
Terraform provider will need to set the environment variables to access the OpenStack API.

See there related KubeOne [documentation](https://docs.kubermatic.com/kubeone/master/guides/credentials/#environment-variables).

### Generate SSH keys

SSH public/private key-pair is used for accessing the master cluster nodes. You can generate these keys locally,
and you will need to set them inside the secret management below.

You can use following command to generate the keys:

```bash
ssh-keygen -t rsa -b 4096 -C "admin@kubermatic.com"
```

You will be prompted to provide a key location, e.g. `~/.ssh/k8s_rsa`, if you choose different location
make sure to update the `ssh_public_key_file` variable in terraform!
### Setup GitHub Secrets for the GitHub Workflow pipeline

Go to your GitHub repository under "Settings" -> "Secrets" and setup following secrets:
 * `OS_AUTH_URL` with value of your URL of OpenStack Identity Service
 * `OS_USERNAME` with value of your username of the OpenStack user
 * `OS_PASSWORD` with value of your password of the OpenStack user
 * `OS_DOMAIN_NAME` with value of your name of the OpenStack domain
 * `OS_TENANT_ID` with value of your ID of the OpenStack tenant
 * `OS_TENANT_NAME` with value of your name of the OpenStack tenant
 * `SOPS_AGE_SECRET_KEY` with value of generated AGE secret key for SOPS (see secrets.md file)
 * `TOKEN_GITHUB` with value of GitHub access token from above step
 * `SSH_PRIVATE_KEY` with value of private SSH key (e.g. content of `~/.ssh/k8s_rsa`)
 * `SSH_PUBLIC_KEY` with value of public SSH key (e.g. content of `~/.ssh/k8s_rsa.pub`)

### Push Content to your Git repository

```bash
git init
git checkout -b main
git add .
git commit -m "Initial setup for KKP on Autopilot"
git remote add origin git@github.com:<GITHUB_OWNER>/<GITHUB_REPOSITORY>
git push -u origin main
```

### Validation
Check the steps of the GitHub Actions after first merge to `main` branch and enjoy the full deployment of KKP at the end!

## High-level Pipeline Design

*tf-validate*
* runs validation of all Terraform modules

*tf-prepare*
* prepare Terraform backend for storing state

*tf-plan*
* prepare Terraform plan based on the stored state
* Terraform state is stored on AWS S3 bucket (created in previous step)

*tf-apply*
* applies the Terraform changes based on a plan (from previous stage)
* runs only on `main` branch
==> VMs, network and LB for k8s on AWS is prepared at this stage

*kubeone-apply*
* performs the cluster provisioning using the `kubeone` tool
* runs only on `main` branch!
==> k8s cluster is ready to use at this stage

*kkp-deploy*
* performs the Kubermatic Kubernetes Platform installation with installer
* runs only on `main` branch!
==> KKP platform with core components is prepared at this stage

*flux-bootstrap*
* initiate Flux v2 using `flux bootstrap github` command
* runs only on `main` branch!
==> monitoring stack for KKP and other KKP resources (seed, preset, project) are delivered after Flux is set up on cluster,
Flux itself is also managed by the same GitHub repository

## Secrets management

Sensitive values are encrypted using the [SOPS](https://fluxcd.io/docs/guides/mozilla-sops/)
together with using the Age secret pair (generated from start.kubermatio.io).

Public AGE key for encryption is: `age15ypxnzg45kl6e7xhvdywyev9x4hw8dk4ncc7v7cg62rkm6rtf3gsq9c2hr`.

## Operational tasks

See the various operational tasks in documentation:
 * [get access to Kubernetes cluster](https://docs.kubermatic.com/kubermatic/master/startio/cheat_sheets/access_to_cluster/)
 * [validate cluster and KKP readiness](https://docs.kubermatic.com/kubermatic/master/startio/cheat_sheets/validate_cluster_health/)
 * [work with secrets using SOPS](https://docs.kubermatic.com/kubermatic/master/startio/cheat_sheets/work_with_secrets/)
 * and [others](https://docs.kubermatic.com/kubermatic/master/startio/cheat_sheets/).
