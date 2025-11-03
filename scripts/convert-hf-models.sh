#!/bin/bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
MODEL_PATH=$1
QUANTIZED_MODEL_PATH=$2
ALIGN=4096
EXEC_DIR=$PROJECT_ROOT
MODEL_NAME=`basename $MODEL_PATH`

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <model_path> <quantized_model_path>"
    exit 1
fi

python convert.py $MODEL_PATH --do_sort --alignment $ALIGN
GGUF_FILE=$(find $MODEL_PATH -name "*f16.gguf" | head -n 1)
if [ ! -f $GGUF_FILE ]; then
    echo "No gguf file [$GGUF_FILE] found in $MODEL_PATH"
    exit 1
fi
$EXEC_DIR/llama-quantize --align $ALIGN $GGUF_FILE $QUANTIZED_MODEL_PATH Q4_0 
echo "Finish converting $MODEL_PATH, quantized model is saved in $QUANTIZED_MODEL_PATH"