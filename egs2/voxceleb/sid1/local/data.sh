#!/usr/bin/env bash

set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=0
stop_stage=1

log "$0 $*"
. utils/parse_options.sh


if [ $# -ne 0 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;
. ./db.sh || exit 1;

if [ ! -e "${VOXCELEB1ROOT}" ]; then
    log "Fill the value of 'VOXCELEB1ROOT' of db.sh"
    exit 1
fi

if [ ! -e "${VOXCELEB2ROOT}" ]; then
    log "Fill the value of 'VOXCELEB2ROOT' of db.sh"
    exit 1
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
  local/make_voxceleb2.pl ${VOXCELEB2ROOT} dev data/voxceleb2_train
  local/make_voxceleb2.pl ${VOXCELEB2ROOT} test data/voxceleb2_test
  # This script creates data/voxceleb1_test and data/voxceleb1_train for latest version of VoxCeleb1.
  # Our evaluation set is the test portion of VoxCeleb1.
  local/make_voxceleb1_v2.pl ${VOXCELEB1ROOT} dev data/voxceleb1_train
  local/make_voxceleb1_v2.pl ${VOXCELEB1ROOT} test data/voxceleb1_test
  # if you downloaded the dataset soon after it was released, you will want to use the make_voxceleb1.pl script instead.
  # local/make_voxceleb1.pl $voxceleb1_root data
  # We'll train on all of VoxCeleb2, plus the training portion of VoxCeleb1.
  # This should give 7,323 speakers and 1,276,888 utterances.
  # utils/combine_data.sh data/train_org data/voxceleb2_train data/voxceleb2_test data/voxceleb1_train
  
  # For first implementation, we only use voxceleb1 data for training, since the voxceleb2 data is m4a format
  # so that it takes a lot of time to be processed.
  cp -r data/voxceleb1_train data/train_org
  # Finally, we divide training data into two sets.
  ./utils/subset_data_dir_tr_cv.sh data/train_org data/train data/dev
  cp data/train/utt2spk data/train/text
  cp data/dev/utt2spk data/dev/text
fi

log "Successfully finished. [elapsed=${SECONDS}s]"
