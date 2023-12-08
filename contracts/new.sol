

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract HealthcareDataToken is ERC20, Ownable {

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
    bool public locked=false;
    bool private reentrancyLock = false;
    mapping(address => HealthData) public patientData;
    mapping(address => mapping(address => bool)) public accessAllowed;
    using Math for uint256;

    //events
    event HealthDataUpdated(address indexed patient, string dataHash, uint256 price, uint256 expiration);
    event DataPurchased(address indexed purchaser, address indexed patient, uint256 price);
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
        require(msg.sender == patientData[msg.sender].ownerOfData || msg.sender == owner(), "Unauthorized access");
        _;
    }

    //functions or methods

    /**
     * @dev Constructor for the HealthcareDataToken contract.
    */

    constructor() ERC20("HealthcareDataToken", "HDT") Ownable(msg.sender){
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    /**
     * @dev Sets health data for a patient.
     * @param _dataHash The hash of the health data.
     * @param _price The price of the health data.
     * @param _isForSale A boolean indicating whether the data is for sale.
     * @param _expiration The timestamp for data expiration.
     */

    function setHealthData(string memory _dataHash, uint256 _price, bool _isForSale, uint256 _expiration) external {
        require(_expiration > block.timestamp, "Expiration time should be in the future");
        patientData[msg.sender].dataHash = _dataHash;
        patientData[msg.sender].price = _price;
        patientData[msg.sender].isForSale = _isForSale;
        patientData[msg.sender].expiration = _expiration;
        patientData[msg.sender].ownerOfData = msg.sender;
        emit HealthDataUpdated(msg.sender, _dataHash, _price, _expiration);
    }

    /**
     * @dev Gets health data for a given patient.
     * @param _patient The address of the patient.
     * @return A tuple containing the owner of the data, data hash, price, sale status, and expiration timestamp.
     */
    function getHealthDataOfSinglePatient(address _patient) external view returns (HealthData memory) {
        // return (patientData[_patient].ownerOfData,patientData[_patient].dataHash, patientData[_patient].price, patientData[_patient].isForSale, patientData[_patient].expiration);
        require(patientData[_patient].ownerOfData==msg.sender,"You don't have any data");
        return patientData[_patient];
    }

    /**
     * @dev Purchases health data for a patient.
     * @param _patient The address of the patient.
     */
    function purchaseData(address _patient) external payable nonReentrant() {
        require(patientData[_patient].isForSale, "Data is not for sale");
        require(msg.value >= patientData[_patient].price, "Insufficient funds to purchase data");
        require(block.timestamp < patientData[_patient].expiration, "Data has expired");

        // uint256 fee = (msg.value * 5) / 100; // 5% fee
        // uint256 amountToPatient = msg.value - fee;
        (bool result,uint256 feeInitial) = msg.value.tryMul(5); // 5% fee
        (bool resultDiv,uint256 fee) = feeInitial.tryDiv(100); // 5% fee
        (bool resultsub,uint256 amountToPatient ) = msg.value.trySub(fee);

        (bool success, ) = payable(owner()).call{value: fee}(""); // Transfer fee to contract owner
        require(success, "Fee transfer failed");

        (success, ) = payable(_patient).call{value: amountToPatient}(""); // Transfer funds to the patient
        require(success, "Amount to patient transfer failed");
        patientData[_patient].isForSale = false;
        _transfer(_patient, msg.sender, patientData[_patient].price);// Transfer tokens
        patientData[_patient].ownerOfData = msg.sender;
         

        emit DataPurchased(msg.sender, _patient, patientData[_patient].price);
    }

    /**
     * @dev Grants access to health data for a specific user.
     * @param _patient The address of the patient.
     * @param _to The address to grant access to.
     */
    function grantAccess(address _patient, address _to) external onlyPatientOrOwner() {
        patientData[_patient].accessList.push(_to);
        accessAllowed[_patient][_to] = true;
        emit AccessGranted(_patient, _to);
    }

    /**
     * @dev Revokes access to health data for a specific user.
     * @param _patient The address of the patient.
     * @param _from The address to revoke access from.
     */
    function revokeAccess(address _patient, address _from) external onlyPatientOrOwner() {
        accessAllowed[_patient][_from] = false;
        emit AccessRevoked(_patient, _from);
    }
    /**
     * @dev Transfers data to another address with access.
     * @param _to The address to transfer data to.
     * @param _amount The amount of data to transfer.
     */
    function transferWithAccess(address _to, uint256 _amount) external {
        require(accessAllowed[msg.sender][_to], "Sender doesn't have access to share data with this address");
        require(patientData[msg.sender].price == _amount, "Incorrect amount for data access");
        _transfer(msg.sender, _to, _amount);
    }

    /**
     * @dev Sets whether the data is for sale.
     * @param _isForSale A boolean indicating whether the data is for sale.
     */
    function setDataForSale(bool _isForSale) external {
        require(msg.sender == owner() || msg.sender== patientData[msg.sender].ownerOfData, "Only owner or patient can set data for sale");
    
        patientData[msg.sender].isForSale = _isForSale;
    
        emit HealthDataUpdated(msg.sender, patientData[msg.sender].dataHash, patientData[msg.sender].price, patientData[msg.sender].expiration);
    }
    
    /**
     * @dev Retrieves the balance of a specific patient.
     * @param _patient The address of the patient.
     * @return The balance of the patient in the token.
     */
    function getPatientBalance(address _patient) external view returns (uint256) {
        return balanceOf(_patient);
    }
    
    /**
     * @dev Gets the access list for a given patient.
     * @param _patient The address of the patient.
     * @return An array of addresses with access to the patient's data.
     */

    function getAccessList(address _patient) external view returns (address[] memory) {
        return patientData[_patient].accessList;
    }

     /**
     * @dev Retrieves the allowance granted to a spender by the owner.
     * @param _owner The owner's address.
     * @param _spender The spender's address.
     * @return The allowance for the spender.
     */
    function getAllowance(address _owner, address _spender) external view returns (uint256) {
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