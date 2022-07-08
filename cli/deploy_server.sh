#!/usr/bin/env bash

#################
# Parse options #
#################

instructions() {
  echo "Usage: $0 [-i] [ -d ] [ -p ] [ -b ] [-a] [-t]" >&2
  echo " -i: initial peer"
  echo " -d: device" >&2
  echo " -p: server identity path" >&2
  echo " -b: block_ids" >&2
  echo " -a: host maddrs" >&2
  echo " -t: whether to run local tests" >&2
  exit 1
}

if [ ! $# -ge 8 ]; then
    instructions
fi

while getopts ":i:d:p:b:a:t:" option; do
    case $option in
        i)  INITIAL_PEER=${OPTARG}
            ;;
        d)  DEVICE=${OPTARG}
            ;;
        p)  SERVER_ID_PATH=${OPTARG}
            ;;
        b)  BLOCK_IDS=${OPTARG}
            ;;
        a)  HOST_MADDR=${OPTARG} # TODO: allow several maddrs 
            ;;
        t)  RUN_LOCAL_TESTS=true
            ;;
        \?) instructions
            ;;
   esac
done


echo "=========="
echo "= Config ="
echo "=========="
echo "Initial peer: ${INITIAL_PEER}"
echo "Device: ${DEVICE}"
echo "Server name: ${SERVER_ID_PATH}"
echo "Server address: ${HOST_MADDR}"
echo "Bloom blocks: ${BLOCK_IDS}"


###########################
# Install or activate env #
###########################

# TODO fix bug with self calling
source ~/miniconda3/etc/profile.d/conda.sh
if conda env list | grep ".*bloom-demo.*"  >/dev/null 2>/dev/null; then
    conda activate bloom-demo
else
    conda create -y --name bloom-demo python=3.8.12 pip
    conda activate bloom-demo

    conda install -y -c conda-forge cudatoolkit-dev==11.3.1 cudatoolkit==11.3.1 cudnn==8.2.1.32
    pip install -i https://pypi.org/simple torch==1.11.0+cu113 torchvision==0.12.0+cu113 -f https://download.pytorch.org/whl/torch_stable.html
    pip install -i https://pypi.org/simple accelerate==0.10.0 huggingface-hub==0.7.0 hivemind==1.1.0
    pip install -i https://pypi.org/simple bitsandbytes-cuda113==0.26.0
    pip install -i https://pypi.org/simple https://github.com/huggingface/transformers/archive/6589e510fa4e6c442059de2fab84752535de9b23.zip
fi


##############
# Local test #
##############

if [ "$RUN_LOCAL_TESTS" = true ] ; then
    echo "Run test on your local machine"
    python -m cli.inference_one_block --config cli/config.json --device ${DEVICE} # see other args
fi


##############
# Run server #
##############

python -m cli.run_server --converted_model_name_or_path bigscience/test-bloomd-6b3 --device ${DEVICE} --initial_peer ${INITIAL_PEER} \
  --block_indices ${BLOCK_IDS} --torch_dtype float32 --identity_path ${SERVER_ID_PATH} --host_maddrs ${HOST_MADDR} &> ${SERVER_ID_PATH}.log
