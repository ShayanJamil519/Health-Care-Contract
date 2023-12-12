const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HealthcareDataToken", function () {
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, patient, user] = await ethers.getSigners();

    const HealthcareDataToken = await ethers.getContractFactory(
      "HealthcareDataToken"
    );
    const healthcareDataTokencontract = await HealthcareDataToken.deploy();
    const HealthcareDataTokenVulnerable = await ethers.getContractFactory(
      "HealthcareDataTokenVulnerable"
    );
    const healthcareDataTokenVcontract =
      await HealthcareDataTokenVulnerable.deploy();

    const malicious = await ethers.getContractFactory("MaliciousContract");
    const maliciouscontract = await malicious.deploy(
      healthcareDataTokenVcontract.target
    );
    return {
      healthcareDataTokencontract,
      owner,
      patient,
      user,
      healthcareDataTokenVcontract,
      maliciouscontract,
    };
  }

  it("should set and get health data", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    const dataHash = "0x123456";
    const name = "mydata";
    const price = 1;
    const isForSale = true;
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(name, dataHash, price, expiration);

    const healthData = await healthcareDataTokencontract
      .connect(patient)
      .getAllMyHealthRecords();

    expect(healthData[0][0]).to.equal(BigInt(1));
    expect(healthData[0][1]).to.equal(name);
    expect(healthData[0][2]).to.equal(dataHash);
    expect(healthData[0][3]).to.equal(price);
    expect(healthData[0][4]).to.equal(isForSale);
    expect(healthData[0][5]).to.equal(patient.address);
    expect(healthData[0][6]).to.equal(expiration);
  });

  it("should allow the purchase of health data", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    const dataHash = "0x123456";
    const name = "mydata";
    const price = 1;
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    // Patient adds health data
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(name, dataHash, price, expiration);

    const initialOwnerBalance = await healthcareDataTokencontract.balanceOf(
      patient.address
    );
    const initialPurchaserBalance = await healthcareDataTokencontract.balanceOf(
      user.address
    );

    // User purchases health data
    const dataPrice = ethers.parseEther("1");
    await healthcareDataTokencontract
      .connect(user)
      .purchaseData(patient.address, 1, { value: dataPrice });

    const finalOwnerBalance = await healthcareDataTokencontract.balanceOf(
      patient.address
    );
    const finalPurchaserBalance = await healthcareDataTokencontract.balanceOf(
      user.address
    );

    // Check balances after the purchase
    expect(finalOwnerBalance).to.equal(initialOwnerBalance - BigInt(1));
    expect(finalPurchaserBalance).to.equal(initialPurchaserBalance + BigInt(1));
  });

  it("should revert if insufficient funds are sent", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    const dataHash = "0x123456";
    const name = "mydata";
    const price = ethers.parseEther("100");
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(name, dataHash, price, expiration);

    await expect(
      healthcareDataTokencontract
        .connect(user)
        .purchaseData(patient.address, 1, { value: 50 })
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
        Math.floor(Date.now() / 1000) + 20
      ); // Expired 1 hour ago

    // Buyer attempts to purchase expired data
    await new Promise((resolve) => setTimeout(resolve, 21000));
    await expect(
      healthcareDataTokencontract
        .connect(user)
        .purchaseData(patient.address, 1, { value: 100 })
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
  it("should grant access", async function () {
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
      .grantAccess(1, user.address);

    // Check that the access is granted
    const healthData = await healthcareDataTokencontract
      .connect(patient)
      .getAllMyHealthRecords();
    console.log("acccc", healthData[0][7]);
    expect(healthData[0][7]).to.includes(user.address);
  });

  it("should revert if unauthorized user grants access", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "Health Record 1",
        "hash123",
        ethers.parseEther("10"),
        Math.floor(Date.now() / 1000) + 3600
      );

    // Unauthorized user attempts to grant access
    await expect(
      healthcareDataTokencontract.connect(user).grantAccess(1, owner.address)
    ).to.be.revertedWith("Unauthorized access");
  });
  it("should retrieve health records of the caller", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    // Add health records for the patient
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "Health Record 1",
        "hash123",
        ethers.parseEther("10"),
        Math.floor(Date.now() / 1000) + 3600
      );
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "Health Record 2",
        "hash456",
        ethers.parseEther("20"),
        Math.floor(Date.now() / 1000) + 7200
      );

    // Get health records of the patient
    const patientHealthRecords = await healthcareDataTokencontract
      .connect(patient)
      .getAllMyHealthRecords();

    // Check the number of health records
    expect(patientHealthRecords.length).to.equal(2);

    // Check the details of the first health record
    expect(patientHealthRecords[0].id).to.equal(1);
    expect(patientHealthRecords[0].name).to.equal("Health Record 1");
    expect(patientHealthRecords[0].dataHash).to.equal("hash123");
    expect(patientHealthRecords[0].price).to.equal(ethers.parseEther("10"));
    expect(patientHealthRecords[0].isForSale).to.equal(true);
    expect(patientHealthRecords[0].ownerOfData).to.equal(patient.address);
    expect(patientHealthRecords[0].expiration).to.be.greaterThan(
      Math.floor(Date.now() / 1000)
    );

    // Check the details of the second health record
    expect(patientHealthRecords[1].id).to.equal(2);
    expect(patientHealthRecords[1].name).to.equal("Health Record 2");
    expect(patientHealthRecords[1].dataHash).to.equal("hash456");
    expect(patientHealthRecords[1].price).to.equal(ethers.parseEther("20"));
    expect(patientHealthRecords[1].isForSale).to.equal(true);
    expect(patientHealthRecords[1].ownerOfData).to.equal(patient.address);
    expect(patientHealthRecords[1].expiration).to.be.greaterThan(
      Math.floor(Date.now() / 1000)
    );
  });
  it("should retrieve health records shared with the caller", async function () {
    const { healthcareDataTokencontract, owner, patient, user } =
      await deployOneYearLockFixture();

    // Add health records and grant access to the user
    await healthcareDataTokencontract
      .connect(patient)
      .addHealthData(
        "Health Record 1",
        "hash123",
        ethers.parseEther("10"),
        Math.floor(Date.now() / 1000) + 3600
      );
    await healthcareDataTokencontract
      .connect(patient)
      .grantAccess(1, user.address);

    const sharedHealthRecords = await healthcareDataTokencontract
      .connect(user)
      .getAllRecordsSharedWithMe();

    // Check the number of shared health records
    expect(sharedHealthRecords.length).to.equal(1);

    // Check the details of the shared health record
    expect(sharedHealthRecords[0].id).to.equal(1);
    expect(sharedHealthRecords[0].name).to.equal("Health Record 1");
    expect(sharedHealthRecords[0].dataHash).to.equal("hash123");
    expect(sharedHealthRecords[0].price).to.equal(ethers.parseEther("10"));
    expect(sharedHealthRecords[0].isForSale).to.equal(true);
    expect(sharedHealthRecords[0].ownerOfData).to.equal(patient.address);
    expect(sharedHealthRecords[0].expiration).to.be.greaterThan(
      Math.floor(Date.now() / 1000)
    );
    expect(sharedHealthRecords[0].accessList).to.includes(user.address);
  });
  it("should not revert if unauthorized user grants access in vulnerable contract", async function () {
    const { healthcareDataTokenVcontract, owner, patient, user } =
      await deployOneYearLockFixture();
    await healthcareDataTokenVcontract
      .connect(patient)
      .addHealthData(
        "Health Record 1",
        "hash123",
        ethers.parseEther("10"),
        Math.floor(Date.now() / 1000) + 3600
      );

    // Unauthorized user attempts to grant access
    await expect(
      healthcareDataTokenVcontract.connect(user).grantAccess(1, owner.address)
    ).to.not.be.revertedWith("Unauthorized access");
  });
});
