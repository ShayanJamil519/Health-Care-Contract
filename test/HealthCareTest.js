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
    // const MC = await ethers.getContractFactory("MaliciousContract");
    // const mcontract = await HealthcareDataToken.deploy();
    //  const malicious = await ethers.getContractFactory("MaliciousContract");
    //  const mcontract = await malicious.deploy();
    // console.log("address", contract);
    return { healthcareDataTokencontract, owner, patient, user };
  }

  it("should set and get health data", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    const dataHash = "0x123456";
    const name = "mydata";
    const price = ethers.parseEther("1");
    const isForSale = true;
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(name, dataHash, price, expiration);
    // console.log("patt", patient);
    // console.log("htt", healthData);
    // console.log("owner", typeof healthData[0]);
    // console.log("owner", healthData[0]);
    const healthData = await healthcareDataTokencontract
      .connect(patient)
      .getHealthDataOfSinglePatient(patient.address);

    // console.log("htttype", healthData);
    expect(healthData[0][0]).to.equal(name);
    expect(healthData[0][1]).to.equal(dataHash);
    expect(healthData[0][2]).to.equal(price);
    expect(healthData[0][3]).to.equal(isForSale);
    expect(healthData[0][4]).to.equal(patient.address);
    expect(healthData[0][5]).to.equal(expiration);
  });

  it("should allow the purchase of health data", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    const initialOwnerBalance = await healthcareDataTokencontract.balanceOf(
      owner.address
    );
    const initialPurchaserBalance = await healthcareDataTokencontract.balanceOf(
      user.address
    );
    const dataHash = "0x123456";
    const name = "mydata";
    const price = ethers.parseEther("1");
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    await healthcareDataTokencontract
      .connect(owner)
      .addHealthData(name, dataHash, price, expiration);

    // Grant access to the purchaser
    // await healthcareDataTokenContract
    //   .connect(owner)
    //   .grantAccess(patient.address, purchaser.address);

    // Purchase health data
    const dataPrice = ethers.parseEther("1");
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .purchaseData(owner.address, 0, { value: dataPrice })
    ).to.emit(healthcareDataTokencontract, "DataPurchased");

    const finalOwnerBalance = await healthcareDataTokencontract.balanceOf(
      owner.address
    );
    const finalPurchaserBalance = await healthcareDataTokencontract.balanceOf(
      user.address
    );

    // Check balances after the purchase
    expect(finalOwnerBalance).to.equal(initialOwnerBalance - dataPrice);
    expect(finalPurchaserBalance).to.equal(initialPurchaserBalance + dataPrice);
  });

  it("should revert if insufficient funds are sent", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    // Assume data is set for sale with a price of 100 wei
    // await healthcareDataTokencontract.connect(owner).setDataForSale(true);
    const dataHash = "0x123456";
    const name = "mydata";
    const price = ethers.parseEther("100");
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(name, dataHash, price, expiration);
    console.log("patt", patient);
    // Buyer attempts to purchase data with insufficient funds
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .purchaseData(patient.address, 0, { value: 50 })
    ).to.be.revertedWith("Insufficient funds to purchase data");
  });

  it("should revert if data has expired", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    // Set health data with expiration time in the past
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "mydata",
        "hash456",
        100,
        Math.floor(Date.now() / 1000) + 10
      ); // Expired 1 hour ago

    // Assume data is set for sale with a price of 100 wei
    // await healthcareDataTokencontract.connect(owner).setDataForSale(true);

    // Buyer attempts to purchase expired data
    await new Promise((resolve) => setTimeout(resolve, 10000));
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .purchaseData(patient.address, { value: 100 })
    ).to.be.revertedWith("Data has expired");
  });
  //  it("should prevent reentrancy attack", async function () {
  //       const { healthcareDataTokencontract, owner, patient, user,mcontract } =
  //         await deployOneYearLockFixture();

  //    // Set the healthcareDataToken contract address in the malicious contract
  //    await mcontract.setHealthcareDataTokenContract(
  //      healthcareDataTokencontract.address
  //    );

  //    // Set health data for the patient
  //    await healthcareDataTokencontract
  //      .connect(patient)
  //      .addHealthData("hash123", 50, Math.floor(Date.now() / 1000) + 3600);

  //    // Grant access to the attacker
  //    await healthcareDataToken
  //      .connect(user)
  //      .grantAccess(patient.address, user.address);

  //    // Perform the reentrancy attack
  //    await maliciousContract
  //      .connect(user)
  //      .attack(patient.address, healthcareDataTokencontract.address);

  //    // Check the results
  //    const patientBalance = await healthcareDataToken
  //      .connect(deployer)
  //      .balanceOf(patient.address);
  //    const attackerBalance = await healthcareDataToken
  //      .connect(deployer)
  //      .balanceOf(attacker.address);

  //    // Ensure that the patient still owns the data and the attacker did not steal funds
  //    expect(patientBalance).to.equal(50);
  //    expect(attackerBalance).to.equal(0);
  //  });

  // it("should prevent reentrancy attack during purchaseData", async () => {
  //   const { healthcareDataTokencontract, owner, patient, user } =
  //     await deployOneYearLockFixture();
  //   // Set health data for the patient
  //   await tokenContract
  //     .connect(patient)
  //     .addHealthData("hash", 10, Math.floor(Date.now() / 1000) + 1000);

  //   // Attacker attempts reentrancy attack
  //   const attackPromise = mockContract
  //     .connect(attacker)
  //     .attack(tokenContract.address, 1);

  //   // Check that the reentrancy guard is working correctly
  //   await expect(attackPromise).to.be.revertedWith("Reentrant call");

  //   // Check that the purchase did not occur
  //   const patientBalance = await tokenContract
  //     .connect(owner)
  //     .balanceOf(patient.address);
  //   expect(patientBalance).to.equal(initialSupply);
  // });
  it("should grant and revoke access", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    // Set health data for the patient
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "mydata",
        "hash123",
        50,
        Math.floor(Date.now() / 1000) + 3600
      );
    // Grant access to a user
    await healthcareDataTokencontract
      .connect(patient)
      .grantAccess(patient.address, user.address);

    // Check that the access is granted
    const accessList = await healthcareDataTokencontract
      .connect(patient)
      .getAccessList(patient.address);
    expect(accessList).to.include(user.address);

    // Revoke access from the user
    await healthcareDataTokencontract
      .connect(patient)
      .revokeAccess(patient.address, user.address);

    // Check that the access is revoked
    const updatedAccessList = await healthcareDataTokencontract
      .connect(patient)
      .getAccessList(patient.address);
    expect(updatedAccessList).to.not.include(user.address);
  });

  it("should transfer data with access", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    // Set health data for the patient
    await healthcareDataTokencontract
      .connect(owner)
      .addHealthData(
        "mydata",
        "hash123",
        50,
        Math.floor(Date.now() / 1000) + 3600
      );

    // Grant access to the user
    await healthcareDataTokencontract
      .connect(owner)
      .grantAccess(owner.address, user.address);

    // User transfers data to another address
    await healthcareDataTokencontract
      .connect(owner)
      .transferWithAccess(user.address, 50);

    // Check that the data is transferred
    const patientBalance = await healthcareDataTokencontract
      .connect(owner)
      .balanceOf(owner.address);
    const userBalance = await healthcareDataTokencontract
      .connect(user)
      .balanceOf(user.address);
    // console.log("babab", patientBalance);
    // console.log("usus", userBalance);

    expect(patientBalance).to.equal(BigInt(999999999999999999999950n));
    expect(userBalance).to.equal(BigInt(50));
  });

  it("should revert if unauthorized user grants access", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    // Unauthorized user attempts to grant access
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .grantAccess(patient.address, owner.address)
    ).to.be.revertedWith("Unauthorized access");
  });

  it("should revert if unauthorized user revokes access", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    // Unauthorized user attempts to revoke access
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .revokeAccess(patient.address, owner.address)
    ).to.be.revertedWith("Unauthorized access");
  });

  it("should revert if incorrect amount for data access", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    // Set health data for the patient
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "mydata",
        "hash789",
        75,
        Math.floor(Date.now() / 1000) + 3600
      );

    // Attempt to transfer incorrect amount of data
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .transferWithAccess(user.address, 10)
    ).to.be.revertedWith("Incorrect amount for data access");
  });
});
