

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HealthcareDataToken is ERC20, Ownable {

    //state variables
    struct HealthData {
        string dataHash;
        uint256 price;
        bool isForSale;
        address ownerOfData;
        uint256 expiration; // Timestamp for data expiration
        address[] accessList; // List of addresses with access to data
    }
    mapping(address => HealthData) public patientData;
    mapping(address => mapping(address => bool)) public accessAllowed;

    //events
    event HealthDataUpdated(address indexed patient, string dataHash, uint256 price, uint256 expiration);
    event DataPurchased(address indexed purchaser, address indexed patient, uint256 price);
    event AccessGranted(address indexed patient, address indexed user);
    event AccessRevoked(address indexed patient, address indexed user);

    //functions or methods

    constructor() ERC20("HealthcareDataToken", "HDT") Ownable(msg.sender){
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function setHealthData(string memory _dataHash, uint256 _price, bool _isForSale, uint256 _expiration) external {
        require(_expiration > block.timestamp, "Expiration time should be in the future");
        patientData[msg.sender].dataHash = _dataHash;
        patientData[msg.sender].price = _price;
        patientData[msg.sender].isForSale = _isForSale;
        patientData[msg.sender].expiration = _expiration;
        patientData[msg.sender].ownerOfData = msg.sender;
        emit HealthDataUpdated(msg.sender, _dataHash, _price, _expiration);
    }

    function getHealthData(address _patient) external view returns (address,string memory, uint256, bool, uint256) {
        return (patientData[_patient].ownerOfData,patientData[_patient].dataHash, patientData[_patient].price, patientData[_patient].isForSale, patientData[_patient].expiration);
    }

    function purchaseData(address _patient) external payable {
        // Reentrancy is a type of attack where an external contract calls back into the current contract before the first invocation is completed. This can lead to unexpected behavior and potentially result in financial losses or other security issues.
        require(patientData[_patient].isForSale, "Data is not for sale");
        require(msg.value >= patientData[_patient].price, "Insufficient funds to purchase data");
        require(block.timestamp < patientData[_patient].expiration, "Data has expired");

        uint256 fee = (msg.value * 5) / 100; // 5% fee
        uint256 amountToPatient = msg.value - fee;

        payable(owner()).transfer(fee); // Transfer fee to contract owner
        payable(_patient).transfer(amountToPatient); // Transfer funds to the patient

        patientData[_patient].isForSale = false;
        _transfer(_patient, msg.sender, patientData[_patient].price); // Transfer tokens

        emit DataPurchased(msg.sender, _patient, patientData[_patient].price);
    }

    function grantAccess(address _patient, address _to) external {
        require(msg.sender == _patient, "Access can only be granted by the patient");
        patientData[_patient].accessList.push(_to);
        accessAllowed[_patient][_to] = true;
        emit AccessGranted(_patient, _to);
    }

    function revokeAccess(address _patient, address _from) external {
        require(msg.sender == _patient || msg.sender == owner(), "Only patient or owner can revoke access");
        accessAllowed[_patient][_from] = false;
        emit AccessRevoked(_patient, _from);
    }

    function transferWithAccess(address _to, uint256 _amount) external {
        require(accessAllowed[msg.sender][_to], "Sender doesn't have access to share data with this address");
        require(patientData[msg.sender].price == _amount, "Incorrect amount for data access");
        _transfer(msg.sender, _to, _amount);
    }

    function setDataForSale(bool _isForSale) external {
        require(msg.sender == owner() || msg.sender== patientData[msg.sender].ownerOfData, "Only owner or patient can set data for sale");
    
        patientData[msg.sender].isForSale = _isForSale;
    
        emit HealthDataUpdated(msg.sender, patientData[msg.sender].dataHash, patientData[msg.sender].price, patientData[msg.sender].expiration);
    }

    function getAccessList(address _patient) external view returns (address[] memory) {
        return patientData[_patient].accessList;
    }

}