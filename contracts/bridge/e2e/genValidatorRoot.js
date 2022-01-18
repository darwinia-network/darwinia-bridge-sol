const { keccakFromHexString } = require("ethereumjs-util");
const { addrs } = require("./fixture")
const { SparseMerkleTree } = require('@darwinia/contracts-verify/src/utils/sparseMerkleTree')

function roundUpToPow2(len) {
    if (len <= 1) {
      return 1
    } else {
      return 2 * roundUpToPow2(parseInt((len + 1) / 2));
    }
}

async function genValidatorRoot() {
  let leafs = addrs
  let len = addrs.length
  let width = roundUpToPow2(len)
  for (let i = len; i < width; i++) {
    leafs.push("0x0000000000000000000000000000000000000000")
  }

  const leavesHashed = leafs.map(addr => keccakFromHexString(addr));
  const validatorsMerkleTree = new SparseMerkleTree(leavesHashed);
  const root = validatorsMerkleTree.rootHex()
  return root
}

genValidatorRoot().then(console.log)

module.exports = {
  genValidatorRoot
}
