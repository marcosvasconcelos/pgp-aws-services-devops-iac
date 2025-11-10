import json, os
def handler(event, context):
    print("pdftotxt triggered:", json.dumps(event))
    target = os.environ.get("TARGET_BUCKET")
    return {"status":"ok","target_bucket":target}
