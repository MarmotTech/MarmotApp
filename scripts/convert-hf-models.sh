#!/bin/bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
HF_MODELS_DIR=$PROJECT_ROOT/hf-models
SCRIPTS_DIR=$PROJECT_ROOT/scripts
MODEL_PATH=$1
ALIGN=4096
EXEC_DIR=$PROJECT_ROOT/bin
MODEL_NAME=`basename $MODEL_PATH`

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <model_path>"
    exit 1
fi

if [ ! -d $HF_MODELS_DIR ]; then
    mkdir $HF_MODELS_DIR
fi

python $SCRIPTS_DIR/convert.py $MODEL_PATH --do_sort --alignment $ALIGN
GGUF_FILE=$(find $MODEL_PATH -name "*f16.gguf" | head -n 1)
if [ ! -f $GGUF_FILE ]; then
    echo "No gguf file [$GGUF_FILE] found in $MODEL_PATH"
    exit 1
fi
$EXEC_DIR/llama-quantize --align $ALIGN $GGUF_FILE $HF_MODELS_DIR/ggml-model-$MODEL_NAME-q4_0.gguf Q4_0 
echo "Finish converting $MODEL_PATH"
echo "The quantized model is saved in $HF_MODELS_DIR/ggml-model-$MODEL_NAME-q4_0.gguf"