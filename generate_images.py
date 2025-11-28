#!/usr/bin/env python3
"""
generate_images.py

Produces imagedefinitions.json for ECS CodeDeploy/CodePipeline.

It expects these environment variables (set by your buildspec):
 - AWS_ACCOUNT_ID
 - AWS_DEFAULT_REGION
 - MICRO_DIR        (relative path to microservices directory)
 - IMAGE_TAG        (tag created in build phase)

Example imagedefinitions.json output:
[
  {"name": "auth", "imageUri": "637423172430.dkr.ecr.us-east-1.amazonaws.com/auth:20251128094648"},
  ...
]
"""
import os
import sys
import json
from pathlib import Path

def fatal(msg):
    print("ERROR:", msg, file=sys.stderr)
    sys.exit(1)

AWS_ACCOUNT_ID = os.getenv("AWS_ACCOUNT_ID")
AWS_DEFAULT_REGION = os.getenv("AWS_DEFAULT_REGION") or os.getenv("AWS_REGION")
MICRO_DIR = os.getenv("MICRO_DIR", "microservices")
IMAGE_TAG = os.getenv("IMAGE_TAG") or os.getenv("CODEBUILD_RESOLVED_SOURCE_VERSION")

if not AWS_ACCOUNT_ID:
    fatal("AWS_ACCOUNT_ID environment variable is required.")
if not AWS_DEFAULT_REGION:
    fatal("AWS_DEFAULT_REGION or AWS_REGION environment variable is required.")
if not IMAGE_TAG:
    fatal("IMAGE_TAG (or CODEBUILD_RESOLVED_SOURCE_VERSION) is required. Set IMAGE_TAG in buildspec or export it into the environment.")
if not MICRO_DIR:
    fatal("MICRO_DIR is required (defaults to 'microservices').")

micro_path = Path(MICRO_DIR)
if not micro_path.exists() or not micro_path.is_dir():
    fatal(f"MICRO_DIR path '{MICRO_DIR}' does not exist or is not a directory.")

services = [p.name for p in micro_path.iterdir() if p.is_dir()]
if not services:
    fatal(f"No service folders found in '{MICRO_DIR}'.")

imagedefs = []
for svc in sorted(services):
    image_uri = f"{AWS_ACCOUNT_ID}.dkr.ecr.{AWS_DEFAULT_REGION}.amazonaws.com/{svc}:{IMAGE_TAG}"
    imagedefs.append({"name": svc, "imageUri": image_uri})

out_path = Path("imagedefinitions.json")
with out_path.open("w") as f:
    json.dump(imagedefs, f, indent=2)

print("Generated imagedefinitions.json:")
print(json.dumps(imagedefs, indent=2))
