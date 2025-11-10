import os
import boto3
import re
import requests
import math
from requests_aws4auth import AWS4Auth

region = os.environ.get('REGION', 'us-east-1')  # prefer env, fallback to us-east-1
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

host = 'https://' + os.environ.get('OPENSEARCH_HOST', '')  # e.g. vpc-...es.amazonaws.com
index = os.environ.get('OPENSEARCH_INDEX', 'documents')
datatype = '_doc'
url = host + '/' + index + '/' + datatype

headers = { "Content-Type": "application/json" }

s3 = boto3.client('s3')
author = ''
date = ''
def listToString(s):
    str1 = ""
    for ele in s:
        str1 += bytes.decode(ele)
    return str1
    
# Lambda execution starts here
def handler(event, context):
    for record in event['Records']:

        # Get the bucket name and key for the new file
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        # Get, read, and split the file into lines
        obj = s3.get_object(Bucket=bucket, Key=key)
        body = obj['Body'].read()
        lines = body.splitlines()
        
        cust_id= key
        url = host + '/' + index + '/' + datatype + '/' + cust_id
        title = lines[0]
        print("Key:", key)
        
        author = lines[1]
        date = lines[2]
        #print("Lines is ", body.split())
        final_body=lines[3:]
        size= len(final_body)
        end_index = math.floor(size/10)
        print("Size: ", size)
        print("End index: ",end_index)
        summary=final_body[1:2]
        print('The binary pdf file type is', type(final_body))
        print("Title:" , title)
        print("Type of title", type(title))
        print("Author:" , author)
        print("Date:", date)
        #print("Body:", final_body)
        print("Summary",summary)
        print("Type of final_body:", type(final_body))
        print("Type of body in string: ",type(listToString(final_body)))
        document = { "Title": title,"Author": author, "Date": date, "Body": listToString(final_body),"Summary": summary }
        #print("Document:",document)
        r = requests.post(url, auth=awsauth, json=document, headers=headers)
        print("Response:", r.text)
        
        

        