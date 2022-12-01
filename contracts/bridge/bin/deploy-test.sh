#!/usr/bin/env bash

set -e

export MODE=test

# 0
# export ETH_GAS_PRICE=10000000000
# . $(dirname $0)/deploy/test/pangoro.sh
# export ETH_GAS_PRICE=2000000000
# . $(dirname $0)/deploy/test/goerli.sh
# export ETH_GAS_PRICE=10000000000
# . $(dirname $0)/deploy/test/bsctest.sh

# 10
export ETH_GAS_PRICE=10000000000
. $(dirname $0)/deploy/test/pangoro-10.sh
export ETH_GAS_PRICE=2000000000
. $(dirname $0)/deploy/test/goerli-10.sh
export ETH_GAS_PRICE=10000000000
. $(dirname $0)/deploy/test/pangoro-11.sh
export ETH_GAS_PRICE=2000000000
. $(dirname $0)/deploy/test/goerli-11.sh
