// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IObject } from "./interfaces/IObject.sol";

/// @title Zen Garden storage contract
contract ZenGarden is AccessControlUpgradeable, IERC1155ReceiverUpgradeable, ReentrancyGuardUpgradeable {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- Map ----------------------------------- */
    // Whether the map can be updated or not
    bool public isMapLocked;
    // Map range
    MapSettings public mapSettings;
    struct MapSettings {
        uint8 minX;
        uint8 maxX;
        uint8 minY;
        uint8 maxY;
    }
    // To grant Whitelist to restrict objects(contractaddress)
    mapping(address => bool) private _whitelist;
    /* --------------------------------- WallPaper ------------------------------ */
    struct WallPaper {
        address contractAddress;
        uint256 tokenId;
    }
    /* --------------------------------- BasePlate ------------------------------ */
    struct BasePlate {
        address contractAddress;
        uint256 tokenId;
    }
    /* --------------------------------- OBJECT --------------------------------- */
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }
    struct Object {
        address contractAddress;
        uint256 tokenId;
        uint8 xStart;
        uint8 yStart;
    }
    struct ObjectInfo {
        address contractAddress;
        uint256 tokenId;
        uint8 xStart;
        uint8 yStart;
        uint8 xEnd;
        uint8 yEnd;
        Link link;
    }
    /* --------------------------------- DEPOSIT -------------------------------- */
    struct Deposit {
        address contractAddress;
        uint256 tokenId;
    }
    struct DepositInfo {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 used;
    }
    /* --------------------------------- LINK ----------------------------------- */
    struct Link {
        string title;
        string url;
        uint256 data;
    }
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- Map ----------------------------------- */
    //  * @notice Return number of Zen Gardens
    uint256 public numberOfLand;
    mapping(string => address) public ownerLists;
    /* --------------------------------- OBJECT --------------------------------- */
    mapping(string => ObjectInfo[]) public userObject;
    /* --------------------------------- WallPaper ------------------------------ */
    mapping(string => WallPaper) public wallPaper;
    /* --------------------------------- BasePlate ------------------------------ */
    mapping(string => BasePlate) public basePlate;
    /* --------------------------------- DEPOSIT -------------------------------- */
    mapping(string => Deposit[]) public userObjectDeposit;
    mapping(string => mapping(address => mapping(uint256 => DepositInfo))) public depositInfo;

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- MAP ----------------------------------- */
    event MapLockStatusChange();
    event CreatedMap(string name, address indexed sender, uint256 numberOfLand);
    event ChangeZenGardenOwner(string name, address indexed sender);
    event WhitelistGranted(address indexed operator, address indexed target);
    event WhitelistRemoved(address indexed operator, address indexed target);
    /* --------------------------------- WALLPAPER ------------------------------ */
    event ChangeWallPaper(string name, address contractAddress, uint256 tokenId);
    /* --------------------------------- BasePlate ------------------------------ */
    event ChangeBasePlate(string name, address contractAddress, uint256 tokenId);
    /* --------------------------------- OBJECT --------------------------------- */
    event WriteObject(string name, address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart);
    event RemoveObject(string name, uint256 index);
    event MapInitialization(string iname, address indexed sender);
    event Save(string name, address indexed sender);
    /* --------------------------------- DEPOSIT -------------------------------- */
    event DepositSuccess(address indexed sender, string name, address contractAddress, uint256 tokenId, uint256 amount);
    event WithdrawSuccess(
        address indexed sender,
        string name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    );
    /* ---------------------------------- LINK ---------------------------------- */
    event WriteLink(string name, address contractAddress, uint256 tokenId, string title, string url, uint256 data);
    event RemoveLink(string name, uint256 index);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotAdminCall(address sender);
    error InvalidWhitelist();
    /* ---------------------------------- MAP ----------------------------------- */
    error MapIsLocked(address sender);
    error NotReadyZenGarden(address sender, address owner);
    error NotZenGardenOwner(address sender, address owner);
    error NotDepositEnough(string name, address contractAddress, uint256 tokenId, uint256 used, uint256 amount);
    error OutofMapRange(uint256 a, string errorBoader);
    error ObjectCollision(ObjectInfo writeObjectInfo, ObjectInfo userObjectInfo, string errorBoader);
    /* --------------------------------- WALLPAPER/BasePlate ------------------------------ */
    error NotFit(address sender, uint256 sizeX, uint256 sizeY, uint256 mapSizeX, uint256 mapSizeY);
    error NotBalance(string name, address sender, address contractAddress, uint256 tokenId);
    /* --------------------------------- DEPOSIT -------------------------------- */
    error NotDeposit(address sender, address owner, uint256 tokenId);
    error NotBalanceEnough(
        string name,
        address sender,
        address contractAddress,
        uint256 tokenId,
        uint256 currentDepositAmount,
        uint256 currentDepositUsed,
        uint256 updateDepositAmount,
        uint256 userBalance
    );
    error withdrawError(uint256 amount, uint256 mapUnUsedBalance);

    /* ---------------------------------- LINK ---------------------------------- */

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address admin) external initializer {
        numberOfLand = 0;
        // Set the x- and y-axis ranges of the map
        mapSettings = MapSettings(0, 8, 0, 8);
        isMapLocked = false;
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Require that map contract has not been locked.
     */
    modifier onlyNotLocked() {
        if (isMapLocked) {
            revert MapIsLocked({ sender: msg.sender });
        }
        _;
    }

    /**
     * @notice Require: Executed by admin.
     */
    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotAdminCall({ sender: msg.sender });
        }
        _;
    }

    /**
     * @notice Require that The operator must be a zengarden owner.
     */
    modifier onlyZenGardenOwner(string memory name) {
        if (ownerOfZenGarden(name) != msg.sender) {
            revert NotZenGardenOwner({ sender: msg.sender, owner: ownerOfZenGarden(name) });
        }
        _;
    }

    /**
     * @notice Require that NFTs must be deposited.
     */
    modifier onlyDepositObject(string memory name, Object memory objectData) {
        address owner = ownerOfZenGarden(name);

        if (depositInfo[name][objectData.contractAddress][objectData.tokenId].amount == 0) {
            revert NotDeposit({ sender: msg.sender, owner: owner, tokenId: objectData.tokenId });
        }
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                     MAP                                    */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
 
    function create(string memory name, address caller) external onlyOwner onlyNotLocked {
        ownerLists[name] = caller;
        unchecked {
            numberOfLand++;
        }
        emit CreatedMap(name, caller, numberOfLand);
    }


    function changeZenGardenOwner(string memory name, address caller) external onlyOwner onlyNotLocked {
        if (ownerOfZenGarden(name) == address(0)) {
            revert NotReadyZenGarden({ sender: msg.sender, owner: ownerOfZenGarden(name) });
        }
        ownerLists[name] = caller;
        emit ChangeZenGardenOwner(name, caller);
    }

    /**
     * @notice Lock map edit action.
     */
    function flipLockMap() external onlyOwner {
        isMapLocked = !isMapLocked;
        emit MapLockStatusChange();
    }

    /**
     * @dev Set the address of the object for whitelist.
     */
    function setWhitelistObject(address newObject) external onlyOwner {
        _whitelist[newObject] = true;
        emit WhitelistGranted(msg.sender, newObject);
    }

    /**
     * @dev remove the address of the object from whitelist.
     */
    function removehitelistObject(address oldObject) external onlyOwner {
        _whitelist[oldObject] = false;
        emit WhitelistRemoved(msg.sender, oldObject);
    }

    /* --------------------------------- WALLPAPER/BasePlate ------------------------------ */


    function checkWallPaper(string memory name) external view returns (WallPaper memory) {
        return wallPaper[name];
    }

    function checkBasePlate(string memory name) external view returns (BasePlate memory) {
        return basePlate[name];
    }

    function _checkConditon(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) internal view {
        // Check that contractAddress is whitelisted.
        if (!_whitelist[contractAddress]) revert InvalidWhitelist();
        IObject _object = IObject(contractAddress);
        IObject.Size memory size = _object.getSize(tokenId);
        // Check that the size of the wall object matches the size of the current map contract
        if ((size.x != mapSettings.maxX) || (size.y != mapSettings.maxY)) {
            revert NotFit(msg.sender, size.x, size.y, mapSettings.maxX, mapSettings.maxY);
        }
        // Check if user has a wall object
        uint256 userBalance = _object.balanceOf(msg.sender, tokenId);
        if (userBalance < 1) {
            revert NotBalance({ name: name, sender: msg.sender, contractAddress: contractAddress, tokenId: tokenId });
        }
    }

    function _changeWallPaper(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) internal {
        address lastWallPaperContractAddress = wallPaper[name].contractAddress;
        uint256 lastWallPaperTokenId = wallPaper[name].tokenId;
        // Withdraw the deposited WALL OBJECT at the same time if it has already been deposited
        if (lastWallPaperContractAddress != address(0)) {
            IObject _lastWallPaper = IObject(lastWallPaperContractAddress);
            _lastWallPaper.safeTransferFrom(address(this), msg.sender, lastWallPaperTokenId, 1, "0x00");
        }
        // Check condition
        _checkConditon(name, contractAddress, tokenId);
        wallPaper[name] = WallPaper(contractAddress, tokenId);
        // Deposit wall object to be set in map contract
        IObject _object = IObject(contractAddress);
        _object.safeTransferFrom(msg.sender, address(this), tokenId, 1, "0x00");
        emit ChangeWallPaper(name, contractAddress, tokenId);
    }


    function _changeBasePlate(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) internal {
        address lastBasePlateContractAddress = basePlate[name].contractAddress;
        uint256 lastBasePlateTokenId = basePlate[name].tokenId;
        // Withdraw the deposited BasePlate OBJECT at the same time if it has already been deposited
        if (lastBasePlateContractAddress != address(0)) {
            IObject _lastBasePlate = IObject(lastBasePlateContractAddress);
            _lastBasePlate.safeTransferFrom(address(this), msg.sender, lastBasePlateTokenId, 1, "0x00");
        }
        // Check condition
        _checkConditon(name, contractAddress, tokenId);
        basePlate[name] = BasePlate(contractAddress, tokenId);
        // Deposit BasePlate object to be set in map contract
        IObject _object = IObject(contractAddress);
        _object.safeTransferFrom(msg.sender, address(this), tokenId, 1, "0x00");
        emit ChangeBasePlate(name, contractAddress, tokenId);
    }

    /* ----------------------------------- VIEW --------------------------------- */
  
    function ownerOfZenGarden(string memory name) public view returns (address) {
        return ownerLists[name];
    }


    function viewZenGarden(string memory name) external view returns (ObjectInfo[] memory) {
        return userObject[name];
    }


    function viewZenGardenArray(string memory name) external view returns (uint256[] memory) {
        if (ownerOfZenGarden(name) == address(0)) {
            revert NotReadyZenGarden({ sender: msg.sender, owner: ownerOfZenGarden(name) });
        }
        uint256 sizeX = mapSettings.maxX;
        uint256 sizeY = mapSettings.maxY;
        uint256[] memory zengardenArray = new uint256[](sizeX * sizeY);
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        for (uint256 i = 0; i < objectLength; ++i) {
            if (_userObjects[i].contractAddress != address(0)) {
                uint256 xStart = _userObjects[i].xStart;
                uint256 xEnd = _userObjects[i].xEnd;
                uint256 yStart = _userObjects[i].yStart;
                uint256 yEnd = _userObjects[i].yEnd;

                for (uint256 x = xStart; x < xEnd; ++x) {
                    for (uint256 y = yStart; y < yEnd; ++y) {
                        zengardenArray[x + sizeY * y] = 1;
                    }
                }
            }
        }
        return zengardenArray;
    }

    /* ----------------------------------- WRITE -------------------------------- */

    function writeObjectToLand(
        string memory name,
        Object memory objectData,
        Link memory link
    ) public onlyNotLocked onlyZenGardenOwner(name) onlyDepositObject(name, objectData) {
        // Check the number of deposit NFTs to write object
        _checkDepositAvailable(name, objectData.contractAddress, objectData.tokenId);
        depositInfo[name][objectData.contractAddress][objectData.tokenId].used++;

        // Check the contractAddress is whitelisted.
        if (!_whitelist[objectData.contractAddress]) revert InvalidWhitelist();
        IObject _object = IObject(objectData.contractAddress);

        // Object contract requires getSize functions for x,y,z
        IObject.Size memory size = _object.getSize(objectData.tokenId);
        ObjectInfo memory writeObjectInfo = ObjectInfo(
            objectData.contractAddress,
            objectData.tokenId,
            objectData.xStart,
            objectData.yStart,
            objectData.xStart + size.x,
            objectData.yStart + size.y,
            link
        );
        // Check map range MapSettings
        _checkMapRange(writeObjectInfo);
        // Check Write Object dosen't collide with previous written objects
        _checkCollision(name, writeObjectInfo);

        userObject[name].push(writeObjectInfo);
        emit WriteObject(name, objectData.contractAddress, objectData.tokenId, objectData.xStart, objectData.yStart);
        emit WriteLink(name, objectData.contractAddress, objectData.tokenId, link.title, link.url, link.data);
    }

    /* ----------------------------------- REMOVE -------------------------------- */
  
    function _removeObjectFromLand(string memory name, uint256 index) internal {
        ObjectInfo memory depositItem = userObject[name][index];
        // Reduce the number of used.
        depositInfo[name][depositItem.contractAddress][depositItem.tokenId].used =
            depositInfo[name][depositItem.contractAddress][depositItem.tokenId].used -
            1;
        // delete object from users zengarden
        delete userObject[name][index];
        emit RemoveObject(name, index);
    }

    /* -------------------------------- WRITE/REMOVE ----------------------------- */

    function _batchRemoveAndWrite(
        string memory name,
        uint256[] memory removeIndexArray,
        Object[] memory objectDatas,
        Link[] memory links
    ) internal {
        uint256 removeIndexArrayLength = removeIndexArray.length;
        if (removeIndexArrayLength != 0) {
            for (uint256 i = 0; i < removeIndexArrayLength; ++i) {
                _removeObjectFromLand(name, removeIndexArray[i]);
            }
        }
        uint256 objectDataLength = objectDatas.length;
        if (objectDataLength != 0) {
            for (uint256 i = 0; i < objectDataLength; ++i) {
                writeObjectToLand(name, objectDatas[i], links[i]);
            }
        }
    }

    /* -------------------------------- INITIALIZATION -------------------------- */

    function mapInitialization(string memory name) external onlyNotLocked onlyZenGardenOwner(name) {
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        for (uint256 i = 0; i < objectLength; ++i) {
            if (_userObjects[i].contractAddress != address(0)) {
                _removeObjectFromLand(name, i);
            }
        }
        delete userObject[name];
        emit MapInitialization(name, msg.sender);
    }

    /* ------------------------------------ SAVE -------------------------------- */

    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        Object[] memory objectDatas,
        Link[] memory links,
        address wcontractAddress,
        uint256 wtokenId,
        address bcontractAddress,
        uint256 btokenId
    ) external nonReentrant onlyNotLocked onlyZenGardenOwner(name) {
        _batchRemoveAndWrite(name, removeIndexArray, objectDatas, links);
        _removeUnUsedUserObject(name);
        if (wcontractAddress != address(0) && wtokenId != 0) {
            _changeWallPaper(name, wcontractAddress, wtokenId);
        }
        if (bcontractAddress != address(0) && btokenId != 0) {
            _changeBasePlate(name, bcontractAddress, btokenId);
        }
        emit Save(name, msg.sender);
    }

    /* ----------------------------------- INTERNAL ------------------------------ */

    function _checkMapRange(ObjectInfo memory writeObjectInfo) private view {
        // fails if writing object is out of range of map
        if (writeObjectInfo.xStart < mapSettings.minX || writeObjectInfo.xStart > mapSettings.maxX) {
            revert OutofMapRange({ a: writeObjectInfo.xStart, errorBoader: "invalid xStart" });
        }
        if (writeObjectInfo.xEnd < mapSettings.minX || writeObjectInfo.xEnd > mapSettings.maxX) {
            revert OutofMapRange({ a: writeObjectInfo.xEnd, errorBoader: "invalid xEnd" });
        }
        if (writeObjectInfo.yStart < mapSettings.minY || writeObjectInfo.yStart > mapSettings.maxY) {
            revert OutofMapRange({ a: writeObjectInfo.yStart, errorBoader: "invalid yStart" });
        }
        if (writeObjectInfo.yEnd < mapSettings.minY || writeObjectInfo.yEnd > mapSettings.maxY) {
            revert OutofMapRange({ a: writeObjectInfo.yEnd, errorBoader: "invalid yEnd" });
        }
    }


    function _checkCollision(string memory name, ObjectInfo memory writeObjectInfo) private view {
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        if (objectLength == 0) {
            return;
        }

        for (uint256 i = 0; i < objectLength; ++i) {
            // Skip if already deleted
            if (_userObjects[i].contractAddress == address(0)) {
                continue;
            }
            // Rectangular objects do not collide when any of the following four conditions are satisfied
            if (
                writeObjectInfo.xEnd <= _userObjects[i].xStart ||
                _userObjects[i].xEnd <= writeObjectInfo.xStart ||
                writeObjectInfo.yEnd <= _userObjects[i].yStart ||
                _userObjects[i].yEnd <= writeObjectInfo.yStart
            ) {
                continue;
            } else {
                revert ObjectCollision({
                    writeObjectInfo: writeObjectInfo,
                    userObjectInfo: _userObjects[i],
                    errorBoader: "invalid objectInfo"
                });
            }
        }
        return;
    }


    function _writeObjectToLand(string memory name, ObjectInfo memory writeObjectInfo) internal {
        depositInfo[name][writeObjectInfo.contractAddress][writeObjectInfo.tokenId].used++;
        userObject[name].push(writeObjectInfo);
    }


    function _removeUnUsedUserObject(string memory name) private {
        uint256 index = 0;
        bool check = false;
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        ObjectInfo[] memory newUserObjects = new ObjectInfo[](objectLength);
        for (uint256 i = 0; i < objectLength; ++i) {
            //  Erases the address(0) array that has already been deleted.
            if (_userObjects[i].contractAddress == address(0)) {
                check = true;
                continue;
            }
            newUserObjects[index] = _userObjects[i];
            index = index + 1;
        }
        if (check) {
            for (uint256 i = 0; i < objectLength; ++i) {
                if (_userObjects[i].contractAddress != address(0)) {
                    _removeObjectFromLand(name, i);
                }
            }
            delete userObject[name];

            for (uint256 i = 0; i < index; ++i) {
                _writeObjectToLand(name, newUserObjects[i]);
            }
        }
        return;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   DEPOSIT                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- VIEW ---------------------------------- */

    function _checkDepositAvailable(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) private view {
        DepositInfo memory _depositInfo = depositInfo[name][contractAddress][tokenId];
        if (_depositInfo.used + 1 > _depositInfo.amount) {
            revert NotDepositEnough(name, contractAddress, tokenId, _depositInfo.used, _depositInfo.amount);
        }
        return;
    }


    function checkDepositStatus(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) external view returns (DepositInfo memory) {
        return depositInfo[name][contractAddress][tokenId];
    }

    function checkAllDepositStatus(string memory name) external view returns (DepositInfo[] memory) {
        uint256 userObjectDepositLength = userObjectDeposit[name].length;
        DepositInfo[] memory deposits = new DepositInfo[](userObjectDepositLength);
        for (uint256 i = 0; i < userObjectDepositLength; ++i) {
            Deposit memory depositObjectInfo = userObjectDeposit[name][i];
            DepositInfo memory tempItem = depositInfo[name][depositObjectInfo.contractAddress][
                depositObjectInfo.tokenId
            ];
            deposits[i] = tempItem;
        }
        return deposits;
    }

    /* --------------------------------- DEPOSIT -------------------------------- */

    function _depositObject(
        string memory name,
        address msgSender,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 currentDepositAmount = depositInfo[name][contractAddress][tokenId].amount;
        uint256 updateDepositAmount = currentDepositAmount + amount;
        uint256 currentDepositUsed = depositInfo[name][contractAddress][tokenId].used;

        if (!_whitelist[contractAddress]) revert InvalidWhitelist();
        IObject _object = IObject(contractAddress);
        uint256 userBalance = _object.balanceOf(msgSender, tokenId);
        if (userBalance < updateDepositAmount - currentDepositAmount) {
            revert NotBalanceEnough({
                name: name,
                sender: msgSender,
                contractAddress: contractAddress,
                tokenId: tokenId,
                currentDepositAmount: currentDepositAmount,
                currentDepositUsed: currentDepositUsed,
                updateDepositAmount: updateDepositAmount,
                userBalance: userBalance
            });
        }
        // Update the deposit amount.
        depositInfo[name][contractAddress][tokenId] = DepositInfo(
            contractAddress,
            tokenId,
            updateDepositAmount,
            currentDepositUsed
        );

        // Maintain a list of deposited contract addresses and token ids for checkAllDepositStatus.
        Deposit memory depositObjectInfo = Deposit(contractAddress, tokenId);
        uint256 userObjectDepositLength = userObjectDeposit[name].length;
        bool check = false;
        for (uint256 i = 0; i < userObjectDepositLength; ++i) {
            Deposit memory depositObjectToken = userObjectDeposit[name][i];
            if (depositObjectToken.contractAddress == contractAddress && depositObjectToken.tokenId == tokenId) {
                check = true;
                break;
            }
        }
        // If user want to deposit new tokenId , add it.
        if (!check) {
            userObjectDeposit[name].push(depositObjectInfo);
        }

        _object.safeTransferFrom(msgSender, address(this), tokenId, amount, "0x00");
        emit DepositSuccess(msgSender, name, contractAddress, tokenId, amount);
    }



    /* --------------------------------- withdraw ------------------------------ */

    function _withdrawObject(
        string memory name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 used = depositInfo[name][contractAddress][tokenId].used;
        uint256 mapUnusedAmount = depositInfo[name][contractAddress][tokenId].amount - used;
        // Cannot withdraw already used objects.
        if (amount > mapUnusedAmount) {
            revert withdrawError(amount, mapUnusedAmount);
        }
        IObject _object = IObject(contractAddress);
        depositInfo[name][contractAddress][tokenId].amount =
            depositInfo[name][contractAddress][tokenId].amount -
            amount;
        _object.safeTransferFrom(address(this), msg.sender, tokenId, amount, "0x00");
        emit WithdrawSuccess(msg.sender, name, contractAddress, tokenId, amount);
    }



    /* ----------------------------------- RECEIVE ------------------------------ */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }


}