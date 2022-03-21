const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");
const { Fixure } = require("./shared/fixture")

chai.use(solidity);
const log = console.log
const thisChainPos = 0
const thisLanePos = 0
const bridgedChainPos = 1
const bridgedLanePos = 1
let owner, addr1, addr2
let feeMarket, outbound, inbound, normalApp
let outboundData, inboundData
let overrides = { value: ethers.utils.parseEther("30") }

const batch = 30
const encoded = "0x"
const send_message = async (nonce) => {
    let to = normalApp.address
    const tx = await outbound.send_message(
      to,
      encoded,
      overrides
    )
    await expect(tx)
      .to.emit(outbound, "MessageAccepted")
      .withArgs(nonce, encoded)
    await logNonce()
}

const logNonce = async () => {
  const out = await outbound.outboundLaneNonce()
  const iin = await inbound.inboundLaneNonce()
  log(`(${out.latest_received_nonce}, ${out.latest_generated_nonce}]                                            ->     (${iin.last_confirmed_nonce}, ${iin.last_delivered_nonce}]`)
}

const receive_messages_proof = async (nonce) => {
    laneData = await outbound.data()
    const from = (await inbound.inboundLaneNonce()).last_delivered_nonce.toNumber()
    const size = nonce - from
    const calldata = Array(laneData.messages.length).fill(encoded)
    let relayer = ethers.Wallet.createRandom();
    await owner.sendTransaction({
        to: relayer.address,
        value: ethers.utils.parseEther("1.0")
    })
    relayer = relayer.connect(ethers.provider)
    const tx = await inbound.connect(relayer).receive_messages_proof(laneData, calldata, "0x", {
      gasLimit: 10000000
    })
    for (let i = 0; i<size; i++) {
      await expect(tx)
        .to.emit(inbound, "MessageDispatched")
        .withArgs(thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, from+i+1, true, "0x")
    }
    await logNonce()
}

const receive_messages_delivery_proof = async (begin, end) => {
    laneData = await inbound.data()
    const tx = await outbound.connect(addr1).receive_messages_delivery_proof(laneData, "0x")
    await expect(tx)
      .to.emit(outbound, "MessagesDelivered")
      .withArgs(begin, end, 1073741823)
    await logNonce()
}

//   out bound lane                                    ->           in bound lane
//   (latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]
//0  (0,  30]   #send_message                            ->     (0, 0]
//1  (0,  30]                                            ->     (0, 30]  #receive_messages_proof
//2  (30, 30]   #receive_messages_delivery_proof         ->     (0, 30]
//3  (30, 30]                                            ->     (30, 30]  #receive_messages_proof
describe("send message tests", () => {

  before(async () => {
    ({ feeMarket, outbound, inbound } = await waffle.loadFixture(Fixure));
    [owner, addr1, addr2] = await ethers.getSigners();

    let overrides = { value: ethers.utils.parseEther("3000") }
    await feeMarket.connect(owner).deposit(overrides)
    await feeMarket.connect(addr1).deposit(overrides)
    await feeMarket.connect(addr2).deposit(overrides)

    const NormalApp = await ethers.getContractFactory("NormalApp")
    normalApp = await NormalApp.deploy()
    outbound.rely(normalApp.address)
    log(" out bound lane                                   ->      in bound lane")
    log("(latest_received_nonce, latest_generated_nonce]   ->     (last_confirmed_nonce, last_delivered_nonce]")
  })

  it("0", async function () {
    for(let i=1; i <=batch; i++) {
      await send_message(i)
    }
  })

  it("1", async function () {
    await receive_messages_proof(batch)
  })

  it("2", async function () {
    await receive_messages_delivery_proof(1, batch)
  })

  // it("3", async function () {
  //   await receive_messages_proof(batch)
  // })

  // it("4", async function () {
  //   for(let i=batch+1; i <=2*batch; i++) {
  //     await send_message(i)
  //     await receive_messages_proof(i)
  //   }
  //   await receive_messages_delivery_proof(batch+1, 2*batch)
  // })
})
