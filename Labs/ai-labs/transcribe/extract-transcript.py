#!/usr/bin/env python3

import json
import sys

if len(sys.argv) != 2:
    print("Usage: python extract-transcript.py <transcript-json>")
    sys.exit(1)

json_file = sys.argv[1]

try:
    with open(json_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    transcript = data["results"]["transcripts"][0]["transcript"]

    print(transcript)

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)