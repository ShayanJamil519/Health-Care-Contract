

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract HealthcareDataTokenVulnerable is ERC20, Ownable {
    /**
     * @title HealthcareDataToken
     * @dev A smart contract for managing healthcare data tokens.
     */

    //state variables
    struct HealthData {
        string dataHash;
        uint256 price;
        bool isForSale;
        address ownerOfData;
        uint256 expiration; // Timestamp for data expiration
        address[] accessList; // List of addresses with access to data
    }
    bool public locked = false;
    bool private reentrancyLock = false;
    mapping(address => HealthData) public patientData;
    uint256 public HealtRecordCount;
    // using Math for uint256;

    //events
    event HealthDataUpdated(
        address indexed patient,
        string dataHash,
        uint256 price,
        uint256 expiration
    );
    event DataPurchased(
        address indexed purchaser,
        address indexed patient,
        uint256 price
    );
    event AccessGranted(address indexed patient, address indexed user);
    event AccessRevoked(address indexed patient, address indexed user);

    /**
     * @dev Modifier to prevent reentrant calls.
     */

    modifier nonReentrant() {
        require(!reentrancyLock, "Reentrant call");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    /**
     * @dev Modifier to restrict access to only the patient or owner.
     */

    modifier onlyPatientOrOwner() {
        require(
            msg.sender == patientData[msg.sender].ownerOfData ||
                msg.sender == owner(),
            "Unauthorized access"
        );
        _;
    }

    //functions or methods

    /**
     * @dev Constructor for the HealthcareDataToken contract.
     */

    constructor() ERC20("HealthcareDataToken", "HDT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    /**
     * @dev Sets health data for a patient.
     * @param _dataHash The hash of the health data.
     * @param _price The price of the health data.
     * @param _expiration The timestamp for data expiration.
     */

    function addHealthData(
        string memory _dataHash,
        uint256 _price,
        uint256 _expiration
    ) external {
        require(
            _expiration > block.timestamp,
            "Expiration time should be in the future"
        );
        HealtRecordCount++;
        patientData[msg.sender].dataHash = _dataHash;
        patientData[msg.sender].price = _price;
        patientData[msg.sender].isForSale = true;
        patientData[msg.sender].expiration = _expiration;
        patientData[msg.sender].ownerOfData = msg.sender;
        emit HealthDataUpdated(msg.sender, _dataHash, _price, _expiration);
    }

    /**
     * @dev Purchases health data for a patient.
     * @param _patient The address of the patient.
     */
    function purchaseData(address _patient) external payable  {
         // Reentrancy is a type of attack where an external contract calls back into the current contract before the first invocation is completed. This can lead to unexpected behavior and potentially result in financial losses or other security issues.Here we are not using any reentrancy guard to prevent it. 
        require(patientData[_patient].isForSale, "Data is not for sale");
        require(
            msg.value >= patientData[_patient].price,
            "Insufficient funds to purchase data"
        );
        require(
            block.timestamp < patientData[_patient].expiration,
            "Data has expired"
        );

        //If msg.value is very large, the multiplication msg.value * 5 could result in an overflow.
        //If msg.value is less than the fee (msg.value * 5), the subtraction msg.value - fee could result in an underflow.

        uint256 fee = (msg.value * 5) / 100; // 5% fee
        uint256 amountToPatient = msg.value - fee;
        // (bool result, uint256 feeInitial) = msg.value.tryMul(5); // 5% fee
        // (bool resultDiv, uint256 fee) = feeInitial.tryDiv(100); // 5% fee
        // (bool resultsub, uint256 amountToPatient) = msg.value.trySub(fee);

        (bool success, ) = payable(owner()).call{value: fee}(""); // Transfer fee to contract owner
        require(success, "Fee transfer failed");

        (success, ) = payable(_patient).call{value: amountToPatient}(""); // Transfer funds to the patient
        require(success, "Amount to patient transfer failed");
        _transfer(_patient, msg.sender, patientData[_patient].price); // Transfer tokens
        patientData[_patient].ownerOfData = msg.sender;

        emit DataPurchased(msg.sender, _patient, patientData[_patient].price);
    }

    // Access control for functions like grantAccess and revokeAccess is not strict, allowing potential misuse.

    /**
     * @dev Grants access to health data for a specific user.
     * @param _patient The address of the patient.
     * @param _to The address to grant access to.
     */
    function grantAccess(
        address _patient,
        address _to
    ) external  {
        patientData[_patient].accessList.push(_to);
        emit AccessGranted(_patient, _to);
    }

    /**
     * @dev Revokes access to health data for a specific user.
     * @param _patient The address of the patient.
     * @param _to The address to revoke access from.
     */
    function revokeAccess(
        address _patient,
        address _to
    ) external  {
        address[] storage accessList = patientData[_patient].accessList;
        for (uint256 i = 0; i < accessList.length; i++) {
            if (accessList[i] == _to) {
                // Swap the address to remove with the last address in the list
                accessList[i] = accessList[accessList.length - 1];
                // Remove the last element (which is the address to be removed)
                accessList.pop();
                emit AccessRevoked(_patient, _to);
                return; // Exit the function after revoking access
            }
        }
        revert("Address not found in access list");
    }

    /**
     * @dev Transfers data to another address with access.
     * @param _to The address to transfer data to.
     * @param _amount The amount of data to transfer.
     */
    function transferWithAccess(address _to, uint256 _amount) external {
        require(
            patientData[msg.sender].price == _amount,
            "Incorrect amount for data access"
        );
        _transfer(msg.sender, _to, _amount);
    }

    /**
     * @dev Gets health data for a given patient.
     * @param _patient The address of the patient.
     * @return A tuple containing the owner of the data, data hash, price, sale status, and expiration timestamp.
     */
    function getHealthDataOfSinglePatient(
        address _patient
    ) external view returns (HealthData memory) {
        // return (patientData[_patient].ownerOfData,patientData[_patient].dataHash, patientData[_patient].price, patientData[_patient].isForSale, patientData[_patient].expiration);
        require(
            patientData[_patient].ownerOfData == msg.sender,
            "You don't have any data"
        );
        return patientData[_patient];
    }

    /**
     * @dev Retrieves the balance of a specific patient.
     * @param _patient The address of the patient.
     * @return The balance of the patient in the token.
     */
    function getPatientBalance(
        address _patient
    ) external view returns (uint256) {
        return balanceOf(_patient);
    }

    /**
     * @dev Gets the access list for a given patient.
     * @param _patient The address of the patient.
     * @return An array of addresses with access to the patient's data.
     */

    function getAccessList(
        address _patient
    ) external view returns (address[] memory) {
        return patientData[_patient].accessList;
    }

    /**
     * @dev Retrieves the allowance granted to a spender by the owner.
     * @param _owner The owner's address.
     * @param _spender The spender's address.
     * @return The allowance for the spender.
     */
    function getAllowance(
        address _owner,
        address _spender
    ) external view returns (uint256) {
        return allowance(_owner, _spender);
    }

    /**
     * @dev Retrieves the total supply of the token.
     * @return The total supply of the token.
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }
}
