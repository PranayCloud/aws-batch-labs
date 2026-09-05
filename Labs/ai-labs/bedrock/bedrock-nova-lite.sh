#!/bin/bash

# ============================================================
# AWS Bedrock Lab - Amazon Nova Lite Model
# ============================================================
# Usage:
# ./bedrock-nova-lite.sh <operation> [prompt]
#
# Operations:
#   text       - Generate text from a prompt
#   summarize  - Summarize a given text
#   sentiment  - Analyze sentiment of a given text
#   translate  - Translate text to a target language
#
# Examples:
# ./bedrock-nova-lite.sh text "Explain what is cloud computing in 3 lines"
# ./bedrock-nova-lite.sh summarize "AWS is a cloud platform by Amazon..."
# ./bedrock-nova-lite.sh sentiment "I love using AWS services!"
# ./bedrock-nova-lite.sh translate "Hello, how are you? | Spanish"
# ============================================================

OPERATION=$1
REGION="us-east-1"
MODEL_ID="amazon.nova-lite-v1:0"

# Validate inputs
if [ $# -lt 2 ]; then
    echo "Usage: $0 <operation> <prompt>"
    echo ""
    echo "Operations:"
    echo "  text       - Generate text from a prompt"
    echo "  summarize  - Summarize a given text"
    echo "  sentiment  - Analyze sentiment of a given text"
    echo "  translate  - Translate text (format: \"<text> | <target-language>\")"
    exit 1
fi

shift
PROMPT="$*"

echo "--------------------------------------------"
echo "Model     : $MODEL_ID"
echo "Region    : $REGION"
echo "Operation : $OPERATION"
echo "--------------------------------------------"
echo ""

# Helper function to call Bedrock and print the response
invoke_nova() {
    local SYSTEM_PROMPT="$1"
    local USER_PROMPT="$2"

    PAYLOAD_FILE=$(python3 -c "import tempfile; print(tempfile.gettempdir() + '/bedrock-payload.json')")
    RESPONSE_FILE=$(python3 -c "import tempfile; print(tempfile.gettempdir() + '/bedrock-response.json')")

    SYSTEM_PROMPT="$1" USER_PROMPT="$2" python3 << 'PYEOF'
import json, os, tempfile
payload = {
    "messages": [{"role": "user", "content": [{"text": os.environ["USER_PROMPT"]}]}],
    "system": [{"text": os.environ["SYSTEM_PROMPT"]}],
    "inferenceConfig": {"maxTokens": 512, "temperature": 0.7}
}
with open(os.path.join(tempfile.gettempdir(), "bedrock-payload.json"), "w") as f:
    json.dump(payload, f)
PYEOF

    RESPONSE=$(aws bedrock-runtime invoke-model \
        --model-id "$MODEL_ID" \
        --region "$REGION" \
        --content-type "application/json" \
        --accept "application/json" \
        --body "fileb://$PAYLOAD_FILE" \
        "$RESPONSE_FILE" 2>&1)

    if [ $? -ne 0 ]; then
        echo "Error calling Bedrock: $RESPONSE"
        exit 1
    fi

    cat "$RESPONSE_FILE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['output']['message']['content'][0]['text'])
"
}

case "$OPERATION" in

text)
    echo "Generating text..."
    echo ""
    invoke_nova \
        "You are a helpful assistant. Answer clearly and concisely." \
        "$PROMPT"
    ;;

summarize)
    echo "Summarizing text..."
    echo ""
    invoke_nova \
        "You are a text summarization assistant. Summarize the given text in a few concise bullet points." \
        "Summarize the following text: $PROMPT"
    ;;

sentiment)
    echo "Analyzing sentiment..."
    echo ""
    invoke_nova \
        "You are a sentiment analysis assistant. Analyze the sentiment of the given text and respond with: Sentiment (Positive/Negative/Neutral/Mixed), a confidence score out of 100, and a one-line reason." \
        "Analyze the sentiment of this text: $PROMPT"
    ;;

translate)
    TEXT=$(echo "$PROMPT" | cut -d'|' -f1 | xargs)
    LANGUAGE=$(echo "$PROMPT" | cut -d'|' -f2 | xargs)
    echo "Translating to $LANGUAGE..."
    echo ""
    invoke_nova \
        "You are a translation assistant. Translate the given text accurately to the requested language. Return only the translated text." \
        "Translate the following text to $LANGUAGE: $TEXT"
    ;;

*)
    echo "Invalid operation: $OPERATION"
    echo ""
    echo "Supported operations:"
    echo "  text"
    echo "  summarize"
    echo "  sentiment"
    echo "  translate"
    exit 1
    ;;

esac

echo ""
echo "--------------------------------------------"
echo "Done."
echo "--------------------------------------------"
