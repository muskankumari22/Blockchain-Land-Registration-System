// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandRegistry {

    // Admin address (deployer becomes admin)
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Structure to store land details
    struct Land {
        address owner;
        string location;
        uint size;
        uint registrationTime;
    }

    // Mapping from land ID to Land struct
    mapping(bytes32 => Land) private landRecords;

    // Mapping to track all lands owned by a user
    mapping(address => bytes32[]) private landsByOwner;

    // Events
    event LandRegistered(
        bytes32 indexed landId,
        address indexed owner,
        string location,
        uint size,
        uint timestamp
    );

    event OwnershipTransferred(
        bytes32 indexed landId,
        address indexed from,
        address indexed to
    );

    event LandDeleted(
        bytes32 indexed landId,
        address indexed by
    );

    // Register new land (Only admin can register)
    function registerLand(
        uint _landId,
        string memory _location,
        uint _size,
        address _owner
    )
        public
        onlyAdmin
    {
        bytes32 landId = generateLandId(_landId);

        require(
            landRecords[landId].owner == address(0),
            "Land already registered"
        );

        require(
            _owner != address(0),
            "Invalid owner address"
        );

        Land memory newLand = Land(
            _owner,
            _location,
            _size,
            block.timestamp
        );

        landRecords[landId] = newLand;

        landsByOwner[_owner].push(landId);

        emit LandRegistered(
            landId,
            _owner,
            _location,
            _size,
            block.timestamp
        );
    }

    // Transfer ownership of land
    function transferOwnership(
        uint _landId,
        address _to
    )
        public
    {
        require(
            _to != address(0),
            "Cannot transfer to zero address"
        );

        bytes32 landId = generateLandId(_landId);

        Land storage land = landRecords[landId];

        require(
            land.owner != address(0),
            "Land not registered"
        );

        require(
            msg.sender == land.owner,
            "Only the owner can transfer ownership"
        );

        address previousOwner = land.owner;

        land.owner = _to;

        // Remove landId from previous owner's list
        _removeLandFromOwner(previousOwner, landId);

        // Add landId to new owner's list
        landsByOwner[_to].push(landId);

        emit OwnershipTransferred(
            landId,
            previousOwner,
            _to
        );
    }

    // Delete land (Only admin or current owner)
    function deleteLand(uint _landId)
        public
    {
        bytes32 landId = generateLandId(_landId);

        Land storage land = landRecords[landId];

        require(
            land.owner != address(0),
            "Land not registered"
        );

        require(
            msg.sender == admin || msg.sender == land.owner,
            "Not authorized to delete land"
        );

        address landOwner = land.owner;

        // Remove from owner's list
        _removeLandFromOwner(landOwner, landId);

        delete landRecords[landId];

        emit LandDeleted(
            landId,
            msg.sender
        );
    }

    // Get land details
    function getLandDetails(uint _landId)
        public
        view
        returns (
            address owner,
            string memory location,
            uint size,
            uint timestamp
        )
    {
        bytes32 landId = generateLandId(_landId);

        Land storage land = landRecords[landId];

        require(
            land.owner != address(0),
            "Land not registered"
        );

        return (
            land.owner,
            land.location,
            land.size,
            land.registrationTime
        );
    }

    // Get all lands owned by a user
    function getMyLands()
        public
        view
        returns (bytes32[] memory)
    {
        return landsByOwner[msg.sender];
    }

    // Check if a land is registered
    function isLandRegistered(uint _landId)
        public
        view
        returns (bool)
    {
        bytes32 landId = generateLandId(_landId);

        return landRecords[landId].owner != address(0);
    }

    // Internal function to generate unique land ID
    function generateLandId(uint _landId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(_landId)
        );
    }

    // Internal function to remove land from owner's list
    function _removeLandFromOwner(
        address _owner,
        bytes32 landId
    )
        internal
    {
        bytes32[] storage lands = landsByOwner[_owner];

        for (uint i = 0; i < lands.length; i++) {

            if (lands[i] == landId) {

                lands[i] = lands[lands.length - 1];

                lands.pop();

                break;
            }
        }
    }
}
