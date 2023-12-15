const { run } = require("hardhat");

const verify = async () => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: "0x61fe8A8517C54a98E5970d4D41fc57B3F404f820",
      constructorArguments: [],
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!");
    } else {
      console.log(e);
    }
  }
};

verify();

module.exports = {
  verify,
};
