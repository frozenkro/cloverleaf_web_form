import json
from pyairtable import Table
import os

def lambda_handler(event, context):
    try:
        print(event['id'])
        importData = queryAirtable(event['id'])
        
        # Format data to be sent to front end
        exportData = {
            "file_name": importData["File"],
            "deadline": importData["Client Review Deadline"],
            "link": importData["Client File URL"]
        }
        
        print("got itemData object")
        return json.dumps(exportData)
    except:
        return 'exception occurred within lambda_handler'

def queryAirtable(id):
    table = Table(os.environ['apiKey'], os.environ['baseID'], os.environ['tableName'])
    record = table.get(id)
    return record['fields']