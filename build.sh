#!/bin/bash

if [ -z "$AT_API_KEY" ]; then 
    echo "Error: environment variable AT_API_KEY is not set"
    exit 1
fi

LAYER_BUCKET_NAME="cloverleaf-lambda-layers"
LAYER_FILE_NAME="pyairtable-lambda-layer.zip"
FUNC_BUCKET_NAME="cloverleaf-lambda-funcs"
GETFILE_FILE_NAME="getfilefromairtable.py"
FILEFEEDBACK_FILE_NAME="postfilefeedbacktoairtable.py"
REGION=$(aws configure get region)
AMPLIFY_APP_NAME="Clwf"

cp ./cloudformation.json cloudformation-deploy.json

if aws s3api head-bucket --bucket "$LAYER_BUCKET_NAME" 2>&1 | grep -q "Not Found"; then
    echo "Creating bucket '$LAYER_BUCKET_NAME'."
    aws s3api create-bucket --bucket "$LAYER_BUCKET_NAME" --region $REGION
else 
    echo "Bucket '$LAYER_BUCKET_NAME' found."
fi

echo "Uploading '$LAYER_FILE_NAME' lambda layer to '$LAYER_BUCKET_NAME'"
aws s3 cp ./$LAYER_FILE_NAME s3://$LAYER_BUCKET_NAME/$LAYER_FILE_NAME


if aws s3api head-bucket --bucket "$FUNC_BUCKET_NAME" 2>&1 | grep -q "Not Found"; then
    echo "Creating bucket '$FUNC_BUCKET_NAME'."
    aws s3api create-bucket --bucket "$FUNC_BUCKET_NAME" --region $REGION
else 
    echo "Bucket '$FUNC_BUCKET_NAME' found."
fi

echo "Uploading '$GETFILE_FILE_NAME' function to '$FUNC_BUCKET_NAME'"
aws s3 cp ./$GETFILE_FILE_NAME s3://$FUNC_BUCKET_NAME/$GETFILE_FILE_NAME

echo "Uploading '$FILEFEEDBACK_FILE_NAME' function to '$FUNC_BUCKET_NAME'"
aws s3 cp ./$FILEFEEDBACK_FILE_NAME s3://$FUNC_BUCKET_NAME/$FILEFEEDBACK_FILE_NAME

echo "Performing string replacements for cloudformation vars"
sed -i "s/<LAMBDA_LAYER_BUCKET>/$LAYER_BUCKET_NAME/g" "./cloudformation-deploy.json"
sed -i "s/<LAMBDA_LAYER_FILE>/$LAYER_FILE_NAME/g" "./cloudformation-deploy.json"
sed -i "s/<FUNC_BUCKET_NAME>/$FUNC_BUCKET_NAME/g" "./cloudformation-deploy.json"
sed -i "s/<GETFILE_FILE_NAME>/$GETFILE_FILE_NAME/g" "./cloudformation-deploy.json"
sed -i "s/<FILEFEEDBACK_FILE_NAME>/$FILEFEEDBACK_FILE_NAME/g" "./cloudformation-deploy.json"
sed -i "s/<AT_API_KEY>/$AT_API_KEY/g" "./cloudformation-deploy.json"

echo "Deploying API and lambdas"
API_URL=$(aws cloudformation deploy --stack-name clwf-api --template-file ./cloudformation-deploy.json --output text)

echo "replacing strings in frontend code and packaging"
sed -i "s/<API_URL>/$API_URL/g" "./client/cloverleaf-web-form.js"
zip -r "cloverleaf-web-form.zip" ./client/

#Might need to create a deployment for this part?
EXISTING_APP_ID=$(aws amplify list-apps --query "apps[?name=='$AMPLIFY_APP_NAME'].appId" --output text)
# if [ -z "$EXISTING_APP_ID" ]; then
#     echo "Existing app found, updating"
#     #update app here
# else 
#     echo "No app found, creating"
#     #deploy app here
# fi