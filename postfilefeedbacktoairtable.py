import json
from pyairtable import Table
import os

def lambda_handler(event, context):
    print (event['id'])
    print (event['form_response'])
    try:
        recid = event['id']
        response = formatResponse(event['form_response'])
        table = Table(os.environ['apiKey'], os.environ['baseID'], os.environ['tableName'])
        print(recid)
        print(response)
        updatedRecord = table.update(recid, { "Status" : response }, typecast=True)
        print(updatedRecord)
        return "Success"
    except:
        return "An error occurred in lambda_handler"

def formatResponse(raw):
    
    if raw == "needs-re-recording":
        return "Needs Re-Recording"
    elif raw == "needs-revision":
        return "Needs Revision"
    elif raw == "approved":
        return "Approved"
    else:
        raise Exception("Invalid response data \"" + raw + "\"")
