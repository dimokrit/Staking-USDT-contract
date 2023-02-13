const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("StakingTTT", function () {
  let acc = [11]
  let stakingTTT
  let tokenTTT

  beforeEach(async function() {
    acc = await ethers.getSigners()
    const TokenTTT = await ethers.getContractFactory("TokenTTT", acc[0])
    tokenTTT = await TokenTTT.deploy()
    await tokenTTT.deployed()

    const StakingTTT = await ethers.getContractFactory("StakingTTT", acc[0])
    stakingTTT = await StakingTTT.deploy(tokenTTT.address)
    await stakingTTT.deployed()
  })

  it("should be deployed", async function() {
    expect(tokenTTT.address).to.be.properAddress
    expect(stakingTTT.address).to.be.properAddress
  })

  it("should be minted on staking contract", async function() {
    const maxToken = 30000*10^18
    const tx = await tokenTTT.mint(maxToken, stakingTTT.address)
    await tx.wait()

    const balance = await tokenTTT.balanceOf(stakingTTT.address)
    expect(balance).to.eq(30000*10^18)
  })

  it("should be staked", async function() {
    const maxToken = 30000*10^18
    const tx = await tokenTTT.mint(maxToken, stakingTTT.address)
    await tx.wait()
    
    for (i = 1; i <= 10; i++) 
      await stakingTTT.connect(acc[i]).stake({ value:100 })
  
    const totalStaked = await stakingTTT.totalStaked()
    expect(totalStaked).to.eq(1000)
  })

  it("should be unstaked", async function() {
    const maxToken = 30000*10^18
    const tx = await tokenTTT.mint(maxToken, stakingTTT.address)
    await tx.wait()
    
    for (i = 1; i <= 10; i++) 
      await stakingTTT.connect(acc[i]).stake({ value:100 })
    
    for (i = 6; i <= 10; i++) 
      await stakingTTT.connect(acc[i]).unstake() 
      
    const totalStaked = await stakingTTT.totalStaked()
    expect(totalStaked).to.eq(500)
  })
})