#!/bin/bash

TEXT=`cat input.txt`

echo "========================================"
echo "Amazon Polly Text-to-Speech Demo"
echo "========================================"
echo "Text we are going to convert to speech:"
echo "----------------------------------------"
echo $TEXT

aws polly synthesize-speech \
    --output-format mp3 \
    --voice-id Joanna \
    --text "$TEXT" \
    output.mp3