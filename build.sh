#!/bin/bash
set -e 

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
API_STACK_NAME="clwf-api"
FE_STACK_NAME="clwf-fe"
FE_BUCKET_NAME="clwf"

cp ./cloudformation-api.json cloudformation-api-deploy.json

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
sed -i "s/<LAMBDA_LAYER_BUCKET>/$LAYER_BUCKET_NAME/g" "./cloudformation-api-deploy.json"
sed -i "s/<LAMBDA_LAYER_FILE>/$LAYER_FILE_NAME/g" "./cloudformation-api-deploy.json"
sed -i "s/<FUNC_BUCKET_NAME>/$FUNC_BUCKET_NAME/g" "./cloudformation-api-deploy.json"
sed -i "s/<GETFILE_FILE_NAME>/$GETFILE_FILE_NAME/g" "./cloudformation-api-deploy.json"
sed -i "s/<FILEFEEDBACK_FILE_NAME>/$FILEFEEDBACK_FILE_NAME/g" "./cloudformation-api-deploy.json"
sed -i "s/<AT_API_KEY>/$AT_API_KEY/g" "./cloudformation-api-deploy.json"

echo "Deploying API and lambdas"
aws cloudformation deploy --stack-name $API_STACK_NAME --template-file ./cloudformation-api-deploy.json 

if [ $? -eq 0 ]; then
    echo "Stack deployed successfully. Retrieving outputs..."

    # Define the output key you want to retrieve
    OUTPUT_KEY="ApiEndpoint"

    # Use AWS CLI to get stack details
    STACK_OUTPUTS=$(aws cloudformation describe-stacks --stack-name $API_STACK_NAME)

    # Extract the specific output value
    API_GATEWAY_URL=$(echo $STACK_OUTPUTS | jq -r ".Stacks[0].Outputs[] | select(.OutputKey == \"$OUTPUT_KEY\") | .OutputValue")

    # Echo or use the API Gateway URL in your script
    echo "API Gateway URL: $API_GATEWAY_URL"
else
    echo "Stack deployment failed."
    exit
fi



cp cloudformation-frontend.json cloudformation-frontend-deploy.json
mkdir client-deploy -p
cp -r ./client/* ./client-deploy/
mv ./client-deploy/cloverleaf-web-form.html ./client-deploy/index.html

echo "replacing strings in frontend code and deploy template"
sed -i "s/<API_URL>/$API_GATEWAY_URL/g" "./client-deploy/cloverleaf-web-form.js"
sed -i "s/<FE_BUCKET_NAME>/$FE_BUCKET_NAME/g" "./cloudformation-frontend-deploy.json"

echo "Deploying frontend bucket host"
aws cloudformation deploy --stack-name $FE_STACK_NAME --template-file ./cloudformation-frontend-deploy.json 

echo "Pushing frontend files to s3"
aws s3 cp ./client-deploy/index.html s3://$FE_BUCKET_NAME/index.html
aws s3 cp ./client-deploy/cloverleaf-web-form.js s3://$FE_BUCKET_NAME/cloverleaf-web-form.js
aws s3 cp ./client-deploy/cloverleaf-web-form_files/back-arrow.svg s3://$FE_BUCKET_NAME/cloverleaf-web-form_files/back-arrow.svg
aws s3 cp ./client-deploy/cloverleaf-web-form_files/cloverleaf_logo.png s3://$FE_BUCKET_NAME/cloverleaf-web-form_files/cloverleaf_logo.png
aws s3 cp ./client-deploy/cloverleaf-web-form_files/main.css s3://$FE_BUCKET_NAME/cloverleaf-web-form_files/main.css

echo "Deploy complete!"