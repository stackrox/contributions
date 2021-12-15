# hardcoded vars
ROX_CENTRAL_ADDRESS=""
ROX_SECRET_TOKEN_LOCATION=""
AWS_REGION="us-west-2"

# Dynamic Stuff
REPOSITORIES=$(aws ecr describe-repositories --region $AWS_REGION | jq -c '.repositories')

# Auth Stuff
export ROX_API_TOKEN=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id $ROX_SECRET_TOKEN_LOCATION | jq -r .SecretString)

echo ${REPOSITORIES} | jq -c '.[]' | while read REPOSITORY
do
    REGISTRY_ID=$(echo ${REPOSITORY} | jq -r '.registryId')
    REPO_NAME=$(echo ${REPOSITORY} | jq -r '.repositoryName')
    BASE_IMAGE_URI=$(echo ${REPOSITORY} | jq -r '.repositoryUri')

    for IMAGE_TAG in $(aws ecr list-images --region $AWS_REGION --registry-id $REGISTRY_ID --repository-name $REPO_NAME | jq -r '.imageIds[].imageTag')
    do
        IMAGE_URI="${BASE_IMAGE_URI}:${IMAGE_TAG}"
        roxctl -e $ROX_CENTRAL_ADDRESS image check --image=$IMAGE_URI
    done
done
