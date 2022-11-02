const { assert, expect } = require("chai")
const { network, deployments, ethers ,getNamedAccounts } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { BigNumber } = require("ethers");


const minPrice = 100000000000000;


describe("CarPooling", function () {

  let CarPooling;
  let carpooling;
  let user1;
  let user2;

  beforeEach(async () => {

    CarPooling = await ethers.getContractFactory("CarPooling");
    [ContractOwner, user1, user2, user3, testArtist, testPlatform] =
      await ethers.getSigners();
    carpooling = await CarPooling.deploy();
    await carpooling.deployed();
  });


  it("Initializes create Carpooling correctly", async function () {
    await carpooling.connect(user1).createCarPooling("A","B",4,4,{value:minPrice})
    const servingState = await carpooling.connect(user1).servingState(user1.address)
    assert.equal(servingState, true)
  });


});