Here's a README.md for your commands:

# FastQWiper Docker Image Deployment and AWS Omics Workflow Guide

This guide explains how to build and deploy the FastQWiper Docker image to Amazon ECR and run it as an AWS Omics workflow.

Github: https://github.com/mazzalab/fastqwiper/tree/main
Sample Data: https://github.com/mazzalab/fastqwiper/tree/main/data
Original snakemake pipeline to translate to nextflow: https://hub.docker.com/r/quan820/snf_fastqwiper
Run the image, cd in pipelines and pick single reads sequential one. 

## Building and Pushing Docker Image to ECR

1. Set your environment variables:
```bash
REGION="us-east-1"
ACCOUNT_ID="your-account-id"
REPO_NAME="fastqwiper"
TAG="latest"
```

2. Create ECR repository:
```bash
aws ecr create-repository \
    --repository-name ${REPO_NAME} \
    --region ${REGION}
```

3. Build Docker image for AMD64 platform:
```bash
docker buildx build --platform linux/amd64 -t fastqwiper:latest .
```

4. Authenticate Docker to ECR:
```bash
aws ecr get-login-password --region ${REGION} | \
    docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
```

5. Tag and push the image:
```bash
docker tag fastqwiper:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${TAG}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${TAG}
```

6. Verify the image deployment:
```bash
aws ecr describe-images \
    --repository-name ${REPO_NAME} \
    --region ${REGION}
```

## Creating and Running AWS Omics Workflow

1. Create the workflow:
```bash
aws omics create-workflow \
  --name fastqwiper_nf \
  --engine NEXTFLOW \
  --definition-uri s3://healthomics-hackathon-sanofi/fastqwiper_nf.zip \
  --main main.nf \
  --region us-east-1
```

2. Start the workflow run:
```bash
aws omics start-run \
--workflow-id 3916580 \
--role-arn arn:aws:iam::913524948358:role/SanofiHackathonHealthOmicsWorkflowRole \
--name fastwiper-test \
--output-uri s3://healthomics-hackathon-sanofi/workflow-outputs/ \
--parameters file://run-params.txt \
--storage-type DYNAMIC \
--retention-mode REMOVE \
--region us-east-1
```

