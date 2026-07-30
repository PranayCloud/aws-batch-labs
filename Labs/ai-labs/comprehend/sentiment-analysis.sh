#!/bin/bash

aws comprehend detect-sentiment \
    --text "I hate programming in Python!" \
    --language-code "en" \
    --region ap-south-1 \
    --output text