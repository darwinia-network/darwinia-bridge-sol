#!/usr/bin/env bash

set -eo pipefail

export Chain0=pangoro
export Chain1=goerli

. $(dirname $0)/nonce.sh

# 0
(from=$Chain0 to=$Chain1 \
. $(dirname $0)/deploy/darwinia.sh)

(from=$Chain1 to=$Chain0 \
. $(dirname $0)/deploy/ethereum.sh)
