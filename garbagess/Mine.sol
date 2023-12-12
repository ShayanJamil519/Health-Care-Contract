// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";

// contract HealthcareDataToken is ERC20, Ownable {
//     address public contractOwner; // address of contract deployer/owner
//     uint256 public healthRecordCount; //  number of health record uploaded.
//     bool private reentrancyLock = false; // lock to track if the buy function is currently executing
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

//     constructor() ERC20("HealthcareDataToken", "HDT") Ownable(msg.sender) {
//         _mint(msg.sender, 1000000 * 10**decimals());
//     }

//     mapping(uint256 => HealthData) public healths;

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

//     modifier nonReentrant() {
//         require(!reentrancyLock, "Reentrant call");
//         reentrancyLock = true;
//         _;
//         reentrancyLock = false;
//     }

//     modifier onlyPatientOrOwner() {
//         require(msg.sender == owner(), "Unauthorized access");
//         _;
//     }

//     // functions:
//     function addHealthData(
//         string memory _name,
//         string memory _dataHash,
//         uint256 _price,
//         uint256 _expiration
//     ) public returns (bool) {
//         require(
//             _expiration > block.timestamp,
//             "Expiration time should be in the future"
//         );
//         healthRecordCount++;

//         healths[healthRecordCount] = HealthData({
//             name: _name,
//             dataHash: _dataHash,
//             price: _price,
//             isForSale: true,
//             ownerOfData: msg.sender,
//             expiration: _expiration,
//             accessList: new address[](0)
//         });

//         _transfer(owner(), msg.sender, 10);

//         emit HealthDataUpdated(
//             msg.sender,
//             healthRecordCount,
//             _dataHash,
//             _price,
//             _expiration
//         );

//         return true;
//     }

//     function grantAccess(uint256 id, address _to)
//         external
//         onlyPatientOrOwner
//         returns (bool)
//     {
//         require(_to != address(0), "Invalid shared address");
//         require(
//             _to != msg.sender,
//             "You can't share with yourself as you are owner of this file"
//         );

//         healths[id].accessList.push(_to);

//         emit AccessGranted(healths[id].ownerOfData, _to);
//         return true;
//     }

//     // buy the data:
//     function purchaseData(address _patient, uint256 _dataId)
//         external
//         payable
//         nonReentrant
//     {
//         require(_dataId >= 0, "Invalid data ID");
//         require(
//             msg.value >= healths[_dataId].price,
//             "Insufficient funds to purchase data"
//         );
//         require(
//             block.timestamp < healths[_dataId].expiration,
//             "Data has expired"
//         );

//         (bool result, uint256 feeInitial) = msg.value.tryMul(5); // 5% fee
//         (bool resultDiv, uint256 fee) = feeInitial.tryDiv(100); // 5% fee
//         (bool resultsub, uint256 amountToPatient) = msg.value.trySub(fee);

//         require(payable(owner()).send(fee), "Fee transfer failed");
//         require(
//             payable(_patient).send(amountToPatient),
//             "Amount to patient transfer failed"
//         );

//         _transfer(_patient, msg.sender, healths[_dataId].price);

//         healths[_dataId].ownerOfData = msg.sender;

//         emit DataPurchased(
//             msg.sender,
//             _patient,
//             _dataId,
//             healths[_dataId].price
//         );
//     }

//     // Get all my records
//     function getAllMyHealthRecords() public view returns (HealthData[] memory) {
//         uint256 count = 0;
//         for (uint256 i = 1; i <= healthRecordCount; i++) {
//             if (healths[i].ownerOfData == msg.sender) {
//                 count++;
//             }
//         }
//         require(count > 0, "You haven't uploaded any health record yet.");

//         HealthData[] memory healthArr = new HealthData[](count);
//         count = 0;
//         for (uint256 i = 1; i <= healthRecordCount; i++) {
//             if (healths[i].ownerOfData == msg.sender) {
//                 healthArr[count] = healths[i];
//                 count++;
//             }
//         }
//         return healthArr;
//     }

//     // Record share with me
//     function getAllRecordsSharedWithMe()
//         public
//         view
//         returns (HealthData[] memory)
//     {
//         uint256 count = 0;
//         for (uint256 i = 1; i <= healthRecordCount; i++) {
//             if (isAddressInArray(healths[i].accessList, msg.sender)) {
//                 count++;
//             }
//         }
//         require(count > 0, "No health records shared with you.");

//         HealthData[] memory healthArr = new HealthData[](count);
//         count = 0;
//         for (uint256 i = 1; i <= healthRecordCount; i++) {
//             if (isAddressInArray(healths[i].accessList, msg.sender)) {
//                 healthArr[count] = healths[i];
//                 count++;
//             }
//         }
//         return healthArr;
//     }

//     function isAddressInArray(address[] memory array, address target)
//         internal
//         pure
//         returns (bool)
//     {
//         for (uint256 i = 0; i < array.length; i++) {
//             if (array[i] == target) {
//                 return true;
//             }
//         }
//         return false;
//     }

//     // Get all market records
//     function getAllMyMarketRecords() public view returns (HealthData[] memory) {
//         uint256 count = 0;
//         for (uint256 i = 1; i <= healthRecordCount; i++) {
//             if (healths[i].isForSale == true) {
//                 count++;
//             }
//         }
//         require(count > 0, "You haven't uploaded any health record yet.");

//         HealthData[] memory healthArr = new HealthData[](count);
//         count = 0;
//         for (uint256 i = 1; i <= healthRecordCount; i++) {
//             if (healths[i].isForSale == true) {
//                 healthArr[count] = healths[i];
//                 count++;
//             }
//         }
//         return healthArr;
//     }
// }