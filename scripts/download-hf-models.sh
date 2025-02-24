#!/bin/bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
MODEL_NAME=$1

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <model_name>"
    exit 1
fi

huggingface-cli download --resume-download $MODEL_NAME