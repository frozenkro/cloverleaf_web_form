## Description:

This project is a web form that allows Cloverleaf customers to review their audio/video files and provide feedback to the engineers. 

## Stack
Client side form: 
 * HTML/CSS/JS
 * Hosted in S3

API layer: 
* API Gateway

Logic: 
* AWS Lambda

Database: 
* Airtable (not included in this project)

## Instructions:

1. Log in to [AWS Console](https://aws.amazon.com/console/)
2. Create Cloud9 Environment
    a. In the top left corner, type "Cloud9" into the search box and select the cloud9 service
    b. Click "Create Environment"
    c. Type a name for the environment
    d. Change "Instance Type" to t3.small
    e. Scroll down and click "Create"
    f. Wait for environment to spin up
3. Open cloud9 environment
4. Deploy Application by entering the following commands in the on-screen terminal
    * `git clone https://github.com/js-bad/cloverleaf_web_form.git`
    * `cd cloverleaf_web_form`
    * `export AT_API_KEY=<your airtable api key>` (replace <your airtable api key> with your airtable api key)
    * `chmod +x ./build.sh`
    * `./build.sh`
5. Wait for stack to deploy