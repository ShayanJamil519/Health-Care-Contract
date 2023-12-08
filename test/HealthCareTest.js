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
  it("should purchase data with correct value", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    const initialPatientBalance = await ethers.provider.getBalance(
      patient.address
    );

    // Assume data is set for sale with a price of 100 wei
    await healthcareDataTokencontract.connect(owner).setDataForSale(true);

    // Buyer purchases data with exact price
    await expect(() =>
      healthcareDataTokencontract
        .connect(buyer)
        .purchaseData(patient.address, { value: 100 })
    ).to.changeEtherBalances([owner, patient, buyer], [5, 100, -100]);

    // Ensure data is no longer for sale
    const isForSale = await healthcareDataTokencontract.getHealthData(
      patient.address
    );
    expect(isForSale).to.equal(false);

    // Ensure the DataPurchased event is emitted
    const purchaseEvent = (
      await healthcareDataTokencontract.queryFilter("DataPurchased")
    )[0];
    expect(purchaseEvent.args.purchaser).to.equal(buyer.address);
    expect(purchaseEvent.args.patient).to.equal(patient.address);
    expect(purchaseEvent.args.price).to.equal(100);
  });

  it("should revert if insufficient funds are sent", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    // Assume data is set for sale with a price of 100 wei
    await healthcareDataTokencontract.connect(owner).setDataForSale(true);

    // Buyer attempts to purchase data with insufficient funds
    await expect(
      healthcareDataTokencontract
        .connect(buyer)
        .purchaseData(patient.address, { value: 50 })
    ).to.be.revertedWith("Insufficient funds to purchase data");
  });

  it("should revert if data is not for sale", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    // Buyer attempts to purchase data when it's not for sale
    await expect(
      healthcareDataTokencontract
        .connect(buyer)
        .purchaseData(patient.address, { value: 100 })
    ).to.be.revertedWith("Data is not for sale");
  });

  it("should revert if data has expired", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    // Set health data with expiration time in the past
    await healthcareDataTokencontract
      .connect(patient)
      .setHealthData(
        "hash456",
        100,
        true,
        Math.floor(Date.now() / 1000) - 3600
      ); // Expired 1 hour ago

    // Assume data is set for sale with a price of 100 wei
    await healthcareDataTokencontract.connect(owner).setDataForSale(true);

    // Buyer attempts to purchase expired data
    await expect(
      healthcareDataTokencontract
        .connect(buyer)
        .purchaseData(patient.address, { value: 100 })
    ).to.be.revertedWith("Expiration time should be in the future");
  });

  it("should prevent reentrancy attack during purchaseData", async () => {
    // Set health data for the patient
    await tokenContract
      .connect(patient)
      .setHealthData("hash", 10, true, 9999999999);

    // Make the data for sale
    await tokenContract.connect(patient).setDataForSale(true);

    // Attacker attempts reentrancy attack
    const attackPromise = mockContract
      .connect(attacker)
      .attack(tokenContract.address, 1);

    // Check that the reentrancy guard is working correctly
    await expect(attackPromise).to.be.revertedWith("Reentrant call");

    // Check that the purchase did not occur
    const patientBalance = await tokenContract
      .connect(owner)
      .balanceOf(patient.address);
    expect(patientBalance).to.equal(initialSupply);
  });
});
