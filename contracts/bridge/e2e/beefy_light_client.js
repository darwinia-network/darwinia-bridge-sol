const { expect } = require("chai")
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const { bootstrap } = require("./helper/fixture")
const chai = require("chai")
const { solidity } = waffle;
const { decodeJustification, decodeConsensusLog } = require("./helper/decode")
const { encodeCommitment, encodeBeefyPayload } = require("./helper/encode")
const { u8aToBuffer, u8aToHex } = require('@polkadot/util')

const { concat } = require("@ethersproject/bytes")
const { keccak256 } = require("@ethersproject/keccak256")

chai.use(solidity)
const log = console.log
let ethClient, subClient, bridge

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}

function hashMessage(message) {
  return keccak256(message)
}

function verifyMessage(message, signature) {
  return ethers.utils.recoverAddress(hashMessage(message), signature);
}

async function test_beefy() {
    log(await ethClient.authority_set())
    let c, cc, s, hash
    while (!c) {
      const block = await subClient.beefy_block()
      hash = block.block.header.hash.toHex()
      if (block.justifications.toString()) {
        log(`Justifications: ${block.block.header.number}, ${block.justifications.toString()}`)
        let js = JSON.parse(block.justifications.toString())
        for (let j of js) {
          if (j[0] == '0x42454546') {
            const justification = decodeJustification(j[1])
            c = justification.toJSON().v1.commitment
            cc = encodeCommitment(c).toHex()
            log(`Encoded commitment: ${cc}`)
            log(`Justification: ${justification.toString()}`)
            let sigs = justification.toJSON().v1.signatures.sigs
            s = sigs.map(sig => {
              let v = parseInt(sig.slice(-2), 16);
              v+=27
              return sig.slice(0, -2) + v.toString(16)
            })
            break
          }
        }
      } else {
        log(`Skip block: ${block.block.header.number}`)
      }
      await sleep(1000)
    }
    log(c)
    const beefy_payload = await subClient.beefy_payload(c.blockNumber, hash)
    const p = encodeBeefyPayload(beefy_payload)
    log(`Encoded beefy payload: ${p.toHex()}`)
    const beefy_commitment = {
      payload: beefy_payload,
      blockNumber: c.blockNumber,
      validatorSetId: c.validatorSetId
    }
    log(beefy_payload)
    const authorities = await subClient.beefy_authorities(hash)
    const raddrs = s.map(signature => {
      return verifyMessage(ethers.utils.arrayify(cc), signature)
    })
    const addrs = authorities.map(authority => {
      return ethers.utils.computeAddress(authority)
    })
    const indices = raddrs.map(a => {
      return addrs.indexOf(a)
    })
    log(s)
    log(raddrs)
    log(addrs)
    log(indices)
    await ethClient.relay_real_head(beefy_commitment, indices, s, raddrs, addrs)
    const message_root = await ethClient.lightClient.latestChainMessagesRoot()
    log(message_root)
    expect(message_root).to.eq(beefy_payload.messageRoot)
    log(await ethClient.authority_set())
}

describe("bridge e2e test: beefy light client", () => {

  before(async () => {
  })

  it("bootstrap", async () => {
    const clients = await bootstrap()
    ethClient = clients.ethClient
    subClient = clients.subClient
    bridge = clients.bridge

    // const unsubscribe = await subClient.api.rpc.beefy.subscribeJustifications((b) => {
    //   console.log(`BEEFY: #${b}`);
    //   unsubscribe()
    // });
    const unsubscribe = await subClient.api.rpc.chain.subscribeNewHeads((header) => {
      console.log(`Chain is at block: #${header.number}`);

    });
  })

  it.skip("set committer", async () => {
    await subClient.set_chain_committer()
  })

  it.skip("beefy header relay", async () => {
    await test_beefy()
  })

  it.skip("beefy authority change", async () => {
    subClient.chill()
    let authorities
    while (!authorities) {
      const block = await subClient.beefy_block()
      let logs = block.block.header.digest.logs
      if (logs.toString()) {
        for(let l of logs) {
          if(l.toJSON().consensus) {
            const css = l.toJSON().consensus
            if(css[0] == '0x42454546') {
              log(css)
              authorities = decodeConsensusLog(log[1]).toJSON().authoritiesChange
              if (authorities) {
                log(authorities)
                await test_beefy()
                break
              }
            }
          }
        }
      } else {
        log(`Skip block: ${block.block.header.number}`)
      }
      await sleep(1000)
    }
  })
})
