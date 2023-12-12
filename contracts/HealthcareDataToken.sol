

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
using Math for uint256;

contract HealthcareDataToken is ERC20, Ownable {
    /**
     * @title HealthcareDataToken
     * @dev A smart contract for managing healthcare data tokens.
     */

    //state variables
    struct HealthData {
        uint256 id;
        string name;
        string dataHash;
        uint256 price;
        bool isForSale;
        address ownerOfData;
        uint256 expiration;
        address[] accessList;
    }
    address public contractOwner; // address of contract deployer/owner
    uint256 public healthRecordCount; //  number of health record uploaded.
    bool private reentrancyLock = false; // lock to track if the buy function is currently executing
    mapping(uint256 => HealthData) public healths;

    //events
    event HealthDataUpdated(
        address indexed patient,
        uint256 dataId,
        string dataHash,
        uint256 price,
        uint256 expiration
    );
    event DataPurchased(
        address indexed purchaser,
        address indexed patient,
        uint256 dataId,
        uint256 price
    );
    event AccessGranted(address indexed patient, address indexed user);
    event AccessRevoked(address indexed patient, address indexed user);

    //modifiers

    modifier nonReentrant() {
        require(!reentrancyLock, "Reentrant call");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier onlyPatientOrOwner(uint256 _id) {
        require(msg.sender == owner()||healths[_id].ownerOfData==msg.sender, "Unauthorized access");
        _;
    }

    /**
     * @dev Constructor for the HealthcareDataToken contract.
     */

    constructor() ERC20("HealthcareDataToken", "HDT") Ownable(msg.sender) {
        _mint(address(this), 1000000 * 10**decimals());
    }

    /**
     * @dev Sets health data for a patient.
     * @param _name The name of the health data.
     * @param _dataHash The hash of the health data.
     * @param _price The price of the health data.
     * @param _expiration The timestamp for data expiration.
     */
    function addHealthData(
        string memory _name,
        string memory _dataHash,
        uint256 _price,
        uint256 _expiration
    ) public returns (bool) {
        require(
            _expiration > block.timestamp,
            "Expiration time should be in the future"
        );
        healthRecordCount++;

        healths[healthRecordCount] = HealthData({
            id: healthRecordCount,
            name: _name,
            dataHash: _dataHash,
            price: _price,
            isForSale: true,
            ownerOfData: msg.sender,
            expiration: _expiration,
            accessList: new address[](0)
        });

        // _transfer(owner(), msg.sender, 10);

        emit HealthDataUpdated(
            msg.sender,
            healthRecordCount,
            _dataHash,
            _price,
            _expiration
        );

        return true;
    }

    /**
     * @dev Grants access to health data for a specific user.
     * @param _id The id of the data for which access will be granted.
     * @param _to The address to grant access to.
     */
    function grantAccess(uint256 _id, address _to)
        external
        onlyPatientOrOwner(_id)
        returns (bool)
    {
        require(_to != address(0), "Invalid shared address");
        require(
            _to != msg.sender,
            "You can't share with yourself as you are owner of this file"
        );

        healths[_id].accessList.push(_to);

        emit AccessGranted(healths[_id].ownerOfData, _to);
        return true;
    }

     /**
     * @dev Purchases health data for a patient.
     * @param _patient The address of the patient.
     * @param _dataId The id of the data to be purchased.
     */
    function purchaseData(address _patient, uint256 _dataId)
        external
        payable
        nonReentrant
    {
        require(_dataId >= 0, "Invalid data ID");
        require(
            msg.value >= healths[_dataId].price,
            "Insufficient funds to purchase data"
        );
        require(
            block.timestamp < healths[_dataId].expiration,
            "Data has expired"
        );

        (bool result, uint256 feeInitial) = msg.value.tryMul(5); // 5% fee
        (bool resultDiv, uint256 fee) = feeInitial.tryDiv(100); // 5% fee
        (bool resultsub, uint256 amountToPatient) = msg.value.trySub(fee);

        require(payable(owner()).send(fee), "Fee transfer failed");
        require(
            payable(_patient).send(amountToPatient),
            "Amount to patient transfer failed"
        );

        // _transfer(_patient, msg.sender, healths[_dataId].price);

        healths[_dataId].ownerOfData = msg.sender;

        emit DataPurchased(
            msg.sender,
            _patient,
            _dataId,
            healths[_dataId].price
        );
    }

    /**
     * @dev Retrieves the data of the address calling this function.
     * @return All data belonging to msg.sender
     */
    function getAllMyHealthRecords() public view returns (HealthData[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= healthRecordCount; i++) {
            if (healths[i].ownerOfData == msg.sender) {
                count++;
            }
        }
        require(count > 0, "You haven't uploaded any health record yet.");

        HealthData[] memory healthArr = new HealthData[](count);
        count = 0;
        for (uint256 i = 1; i <= healthRecordCount; i++) {
            if (healths[i].ownerOfData == msg.sender) {
                healthArr[count] = healths[i];
                count++;
            }
        }
        return healthArr;
    }

    /**
     * @dev Retrieves the data of all users that is share with the address calling this function.
     * @return All Users data that is shared with msg.sender
     */
    function getAllRecordsSharedWithMe()
        public
        view
        returns (HealthData[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= healthRecordCount; i++) {
            if (isAddressInArray(healths[i].accessList, msg.sender)) {
                count++;
            }
        }
        require(count > 0, "No health records shared with you.");

        HealthData[] memory healthArr = new HealthData[](count);
        count = 0;
        for (uint256 i = 1; i <= healthRecordCount; i++) {
            if (isAddressInArray(healths[i].accessList, msg.sender)) {
                healthArr[count] = healths[i];
                count++;
            }
        }
        return healthArr;
    }

    /**
     * @dev Checks if a user exist in an array
     * @return True if user is in array
     */
    function isAddressInArray(address[] memory array, address target)
        public
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Retrieves the data of all users.
     * @return All Users data
     */
    function getAllMyMarketRecords() public view returns (HealthData[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= healthRecordCount; i++) {
            if (healths[i].isForSale == true) {
                count++;
            }
        }
        require(count > 0, "You haven't uploaded any health record yet.");

        HealthData[] memory healthArr = new HealthData[](count);
        count = 0;
        for (uint256 i = 1; i <= healthRecordCount; i++) {
            if (healths[i].isForSale == true) {
                healthArr[count] = healths[i];
                count++;
            }
        }
        return healthArr;
    }
}