---
name: deploy-to-aws
description: Use when a project must be deployed to AWS instead of Cloudflare
version: 1.0.0
tags: [deployment, aws, ops]
metadata:
  hermes:
    tags: [deployment, aws, ops]
    related_skills: [post-deploy-followup, setup-monitoring, health-check, rollback]
---

## Overview

Deploys to AWS when Cloudflare is not suitable. Supports Elastic Beanstalk,
Lambda, or ECS depending on `AWS_DEPLOYMENT_TARGET`. Captures the URL and
runs `post-deploy-followup`.

## When to Use

- `DEPLOYMENT_TARGET=aws` is set in environment or memory
- Project requires managed VMs, long-running processes, or AWS-native services
- Cloudflare Workers are not a fit (e.g. heavy compute, long-running jobs, non-HTTP workloads)

## Prerequisites

- AWS CLI: `aws configure`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` set
- `AWS_DEPLOYMENT_TARGET` set to `elastic-beanstalk`, `lambda`, or `ecs`
- For Elastic Beanstalk: `eb` CLI installed and application/environment exist
- For Lambda: function name and IAM role configured
- For ECS: cluster and service configured
- Project has `/api/health` endpoint

## Procedure

**Pre-deploy checklist:**
1. `git status` clean
2. `AGENTS.md` committed
3. `/api/health` endpoint exists
4. `npm run build` passes

**Elastic Beanstalk:**
```bash
npm run build
zip -r deploy.zip . -x node_modules/** -x .env.local -x .git/**
eb deploy $AWS_EB_ENVIRONMENT_NAME --staged
```

**Lambda:**
```bash
npm run build
zip -r function.zip dist/
aws lambda update-function-code --function-name $AWS_LAMBDA_FUNCTION_NAME --zip-file fileb://function.zip
```

**ECS:**
```bash
# Build and push to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ECR_REGISTRY
docker build -t $AWS_ECR_REPO:$IMAGE_TAG .
docker push $AWS_ECR_REPO:$IMAGE_TAG
aws ecs update-service --cluster $AWS_ECS_CLUSTER --service $AWS_ECS_SERVICE --force-new-deployment
```

**Save deployment context:**
1. Save URL to Hermes memory: key `last-deployment-url`, value URL string
2. Save target to Hermes memory: key `deployment-target`, value `aws`
3. Run `post-deploy-followup`

## Pitfalls

- AWS deployments take longer than Cloudflare; wait for the service to reach a steady state before running health-check.
- IAM permissions must include the target service (Elastic Beanstalk, Lambda, ECS, ECR).
- Never commit `AWS_SECRET_ACCESS_KEY`.
- Lambda cold starts can cause health-check timeouts — retry once.

## Verification

- AWS command exits 0 and service URL is reachable
- `last-deployment-url` and `deployment-target=aws` saved to Hermes memory
- `post-deploy-followup` started
