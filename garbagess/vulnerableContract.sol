// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";

// contract HealthcareDataTokenM is ERC20, Ownable {
//     using Math for uint256;

//     struct HealthData {
//         string name;
//         string dataHash;
//         uint256 price;
//         bool isForSale;
//         address ownerOfData;
//         uint256 expiration;
//         address[] accessList;
//     }

//     bool public locked = false;
//     bool private reentrancyLock = false;
//     mapping(address => HealthData[]) public patientData;
//     uint256 public healthRecordCount;
//     using Math for uint256;
//     HealthData[] public allUsersData;

//     event HealthDataUpdated(
//         address indexed patient,
//         uint256 dataId,
//         string dataHash,
//         uint256 price,
//         uint256 expiration
//     );
//     event DataPurchased(
//         address indexed purchaser,
//         address indexed patient,
//         uint256 dataId,
//         uint256 price
//     );
//     event AccessGranted(address indexed patient, address indexed user);
//     event AccessRevoked(address indexed patient, address indexed user);


//     constructor() ERC20("HealthcareDataToken", "HDT") Ownable(msg.sender) {
//         _mint(msg.sender, 1000000 * 10 ** decimals());
//     }

//     function addHealthData(
//         string memory _name,
//         string memory _dataHash,
//         uint256 _price,
//         uint256 _expiration
//     ) external {
//         require(
//             _expiration > block.timestamp,
//             "Expiration time should be in the future"
//         );
//         healthRecordCount++;

//         HealthData memory newHealthData = HealthData({
//             name: _name,
//             dataHash: _dataHash,
//             price: _price,
//             isForSale: true,
//             ownerOfData: msg.sender,
//             expiration: _expiration,
//             accessList: new address[](0)
//         });

//         patientData[msg.sender].push(newHealthData);
//         allUsersData.push(newHealthData);
//         _transfer(owner(), msg.sender,_price+5); 

//         emit HealthDataUpdated(msg.sender, healthRecordCount, _dataHash, _price, _expiration);
//     }

//     function purchaseData(address _patient, uint256 _dataId) external payable  {
//         // Reentrancy is a type of attack where an external contract calls back into the current contract before the first invocation is completed. This can lead to unexpected behavior and potentially result in financial losses or other security issues.Here we are not using any reentrancy guard to prevent it. 
//         require(_dataId >= 0 && _dataId <= patientData[_patient].length, "Invalid data ID");
//         HealthData storage dataEntry = patientData[_patient][_dataId ];
        
//         require(dataEntry.isForSale, "Data is not for sale");
//         require(msg.value >= dataEntry.price, "Insufficient funds to purchase data");
//         require(block.timestamp < dataEntry.expiration, "Data has expired");

//         //If msg.value is very large, the multiplication msg.value * 5 could result in an overflow.
//         //If msg.value is less than the fee (msg.value * 5), the subtraction msg.value - fee could result in an underflow.

//         uint256 fee = (msg.value * 5) / 100; // 5% fee
//         uint256 amountToPatient = msg.value - fee;

//         require(payable(owner()).send(fee), "Fee transfer failed");
//         require(payable(_patient).send(amountToPatient), "Amount to patient transfer failed");
        
//         _transfer(_patient, msg.sender, dataEntry.price);
        
//         dataEntry.ownerOfData = msg.sender;
//         patientData[msg.sender].push(dataEntry);
//         allUsersData.push(dataEntry);
//         emit DataPurchased(msg.sender, _patient, _dataId, dataEntry.price);
//     }

//     // Access control for functions like grantAccess and revokeAccess is not strict, allowing potential misuse.


//     function grantAccess(address _patient, address _to, uint256 _dataId) external  {
//         require(_dataId >= 0 && _dataId <= patientData[_patient].length, "Invalid data ID");
//         HealthData storage dataEntry = patientData[_patient][_dataId ];
        
//         dataEntry.accessList.push(_to);
//         emit AccessGranted(_patient, _to);
//     }

//     function revokeAccess(address _patient, address _to, uint256 _dataId) external {
//         require(_dataId >= 0 && _dataId <= patientData[_patient].length, "Invalid data ID");
//         HealthData storage dataEntry = patientData[_patient][_dataId];
        
//         address[] storage accessList = dataEntry.accessList;
//         for (uint256 i = 0; i < accessList.length; i++) {
//             if (accessList[i] == _to) {
//                 accessList[i] = accessList[accessList.length - 1];
//                 accessList.pop();
//                 emit AccessRevoked(_patient, _to);
//                 return;
//             }
//         }
//         revert("Address not found in access list");
//     }

//     function transferWithAccess(address _patient, uint256 _dataId, address _to, uint256 _amount) external {
//         require(_dataId >= 0 && _dataId <= patientData[_patient].length, "Invalid data ID");
//         HealthData storage dataEntry = patientData[_patient][_dataId ];
        
//         require(dataEntry.price == _amount, "Incorrect amount for data access");
//         _transfer(_patient, _to, _amount);
//     }

//     function getHealthDataOfSinglePatient(address _patient) external view returns (HealthData[] memory) {
     
//         return patientData[_patient];
//     }

//     function getPatientBalance(address _patient) external view returns (uint256) {
//         return balanceOf(_patient);
//     }

//     // function getAccessList(address _patient, uint256 _dataId) external view returns (address[] memory) {
//     //     require(_dataId > 0 && _dataId <= patientData[_patient].length, "Invalid data ID");
//     //     return patientData[_patient][_dataId - 1].accessList;
//     // }
//     function getAccessList(address _patient) external view returns (address[][] memory) {
//         uint256 dataCount = patientData[_patient].length;
//         address[][] memory accessLists = new address[][](dataCount);

//         for (uint256 i = 0; i < dataCount; i++) {
//             accessLists[i] = patientData[_patient][i].accessList;
//         }

//         return accessLists;
// }

//     function getAllowance(address _owner, address _spender) external view returns (uint256) {
//         return allowance(_owner, _spender);
//     }

//     function getTotalSupply() external view returns (uint256) {
//         return totalSupply();
//     }

//     function getAllUsersData() external view returns (HealthData[] memory) {
//         return allUsersData;
//     }
// }
