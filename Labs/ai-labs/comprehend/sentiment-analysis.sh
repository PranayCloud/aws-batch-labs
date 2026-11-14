#!/bin/bash

aws comprehend detect-sentiment \
    --text "$1" \
    --language-code "en" \
    --region us-east-1 \
    --output text