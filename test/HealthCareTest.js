const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HealthcareDataToken", function () {
  let healthcareDataToken;
  let owner, patient, user;
  //    let contract;

  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, patient, user] = await ethers.getSigners();

    // const Lock = await ethers.getContractFactory("Lock");
    const HealthcareDataToken = await ethers.getContractFactory(
      "HealthcareDataToken"
    );
    const healthcareDataTokencontract = await HealthcareDataToken.deploy();
    //  const malicious = await ethers.getContractFactory("MaliciousContract");
    //  const mcontract = await malicious.deploy();
    // console.log("address", contract);
    return { healthcareDataTokencontract, owner, patient, user };
  }

  //   beforeEach(async function () {
  //     [owner, patient, user] = await ethers.getSigners();

  //     const HealthcareDataToken = await ethers.getContractFactory(
  //       "HealthcareDataToken"
  //     );
  //     healthcareDataToken = await HealthcareDataToken.deploy();
  //     await healthcareDataToken.deployed();
  //   });

  it("should set and get health data", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    const dataHash = "0x123456";
    const price = ethers.parseEther("1");
    const isForSale = true;
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    await healthcareDataTokencontract
      .connect(patient)
      .setHealthData(dataHash, price, isForSale, expiration);

    const healthData = await healthcareDataTokencontract.getHealthData(
      patient.address
    );
    console.log("patt", patient);
    console.log("htt", healthData);
    console.log("owner", typeof healthData[0]);
    console.log("owner", healthData[0]);
    // console.log("htttype", typeof healthData);
    expect(healthData[0]).to.equal(patient.address);
    expect(healthData[1]).to.equal(dataHash);
    expect(healthData[2]).to.equal(price);
    expect(healthData[3]).to.equal(isForSale);
    expect(healthData[4]).to.equal(expiration);
  });

  //   it("should purchase data", async function () {
  //     const dataHash = "0x123456";
  //     const price = ethers.utils.parseEther("1");
  //     const isForSale = true;
  //     const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

  //     await healthcareDataToken
  //       .connect(patient)
  //       .setHealthData(dataHash, price, isForSale, expiration);

  //     const initialOwnerBalance = await ethers.provider.getBalance(
  //       patient.address
  //     );
  //     const initialContractBalance = await ethers.provider.getBalance(
  //       healthcareDataToken.address
  //     );

  //     await expect(() =>
  //       healthcareDataToken
  //         .connect(user)
  //         .purchaseData(patient.address, { value: price })
  //     ).to.changeEtherBalances([patient, healthcareDataToken], [-price, price]);

  //     const healthData = await healthcareDataToken.getHealthData(patient.address);
  //     expect(healthData.isForSale).to.equal(false);

  //     const finalOwnerBalance = await ethers.provider.getBalance(patient.address);
  //     const finalContractBalance = await ethers.provider.getBalance(
  //       healthcareDataToken.address
  //     );

  //     expect(finalOwnerBalance).to.equal(initialOwnerBalance.add(price));
  //     expect(finalContractBalance).to.equal(initialContractBalance.sub(price));
  //   });

  // Add more test cases for other functions as needed
});
