const EthClient = require('./ethclient').EthClient
const SubClient = require('./subclient').SubClient

// const evm_endpoint = "http://127.0.0.1:8545"
// const dvm_endpoint = "http://127.0.0.1:9933"
const evm_endpoint = "http://192.168.2.100:8545"
const dvm_endpoint = "http://192.168.2.100:9933"

const addr1 = "0x3DFe30fb7b46b99e234Ed0F725B5304257F78992"
const addr2 = "0xB3c5310Dcf15A852b81d428b8B6D5Fb684300DF9"
const addr3 = "0xf4F07AAe298E149b902993B4300caB06D655f430"
const addrs = [addr1, addr2, addr3]

const priv1 = "d2f4e4eaf19bc75ebb1d8d9f7399fbb554ce92c5c2cb04610651db9860b080b3"
const priv2 = "9438704f5bd45bbcfc59e6989db378112db0c070e703249b32f0f298b753313e"
const priv3 = "482e54d8bb063ffa1f39a66f48235eac0e13988bede00be37728c7eafb762b32"
const privs = [priv1, priv2, priv3]

const fees = [
  ethers.utils.parseEther("10"),
  ethers.utils.parseEther("20"),
  ethers.utils.parseEther("30")
]

async function bootstrap() {
  const ethClient = new EthClient(evm_endpoint)
  const subClient = new SubClient(dvm_endpoint)
  await ethClient.init(privs, fees)
  await subClient.init(privs, fees)
  return { ethClient, subClient }
}

module.exports = {
  addrs,
  bootstrap
}
