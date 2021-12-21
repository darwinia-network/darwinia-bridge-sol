const Fixure = async () => {
  const VAULT = "0x0000000000000000000000000000000000000000"
  const COLLATERAL_PERORDER = ethers.utils.parseEther("10")
  const ASSIGNED_RELAYERS_NUMBER = 3;
  const SLASH_TIME = 100
  const RELAY_TIME = 100
  const [one, two, three] = await ethers.getSigners();
  const FeeMarket = await ethers.getContractFactory("FeeMarket")
  const feeMarket = await FeeMarket.deploy(VAULT, COLLATERAL_PERORDER, ASSIGNED_RELAYERS_NUMBER, SLASH_TIME, RELAY_TIME)
  let overrides = {
      value: ethers.utils.parseEther("100")
  }
  const [oneFee, twoFee, threeFee] = [
    ethers.utils.parseEther("10"),
    ethers.utils.parseEther("20"),
    ethers.utils.parseEther("30")
  ]
  await feeMarket.connect(one).enroll("0x0000000000000000000000000000000000000001", oneFee, overrides)
  await feeMarket.connect(two).enroll(one.address, twoFee, overrides)
  await feeMarket.connect(three).enroll(two.address, threeFee, overrides)

  const thisChainPos = 0
  const thisLanePos = 0
  const bridgedChainPos = 1
  const bridgedLanePos = 1
  const MockLightClient = await ethers.getContractFactory("MockLightClient")
  const lightClient = await MockLightClient.deploy()
  const OutboundLane = await ethers.getContractFactory("OutboundLane")
  outbound = await OutboundLane.deploy(lightClient.address, thisChainPos, thisLanePos, bridgedChainPos, bridgedLanePos, 1, 0, 0)
  await outbound.rely(one.address)
  const InboundLane = await ethers.getContractFactory("InboundLane")
  inbound = await InboundLane.deploy(lightClient.address, bridgedChainPos, bridgedLanePos, thisChainPos, thisLanePos, 0, 0)

  await feeMarket.totalSupply()
  await feeMarket.setOutbound(outbound.address, 1)
  await outbound.setFeeMarket(feeMarket.address)
  return {feeMarket, outbound, inbound}
}

module.exports = {
  Fixure
}
