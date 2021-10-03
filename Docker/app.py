import json
import boto3

s3 = boto3.client('s3')

def handler(event, context):

    DeviceID = event["DEVICEID"]
    TestID = event["TESTID"]
    TimeStamp = event["TIMESTAMP"]
    BucketName = event["BUCKET_NAME"];

    resultToUpload = {}
    resultToUpload['DeviceID'] = DeviceID
    resultToUpload['TestID'] = TestID
    resultToUpload['Result'] = "OK"
    resultToUpload['TimeStamp'] = TimeStamp
    resultToUpload['ContainerID'] = "net-tester-python"

    tagToAdd = 'makePublic={}&ContainerID={}'.format("yes","net-tester-python")

    fileName = DeviceID + "-" + TestID + "-" + TimeStamp + ".json"

    uploadByteStream = bytes(json.dumps(resultToUpload).encode('UTF-8'))

    s3.put_object(Bucket=BucketName, Key=fileName, Body=uploadByteStream, Tagging=tagToAdd)

    response = {
        "statusCode": 200,
        "body": uploadByteStream
    }
    return response
