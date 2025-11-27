import os, json

micro_dir = "microservices"
services = [
    s for s in os.listdir(micro_dir)
    if os.path.isdir(os.path.join(micro_dir, s))
]

account = os.environ["AWS_ACCOUNT_ID"]
region = os.environ["AWS_DEFAULT_REGION"]
commit = os.environ["CODEBUILD_RESOLVED_SOURCE_VERSION"]

output = [{
    "name": s,
    "imageUri": f"{account}.dkr.ecr.{region}.amazonaws.com/{s}:{commit}"
} for s in services]

with open("imagedefinitions.json", "w") as f:
    f.write(json.dumps(output, indent=2))

print("Generated imagedefinitions.json:")
print(json.dumps(output, indent=2))
