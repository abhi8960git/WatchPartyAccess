// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract WatchParty {
    struct Party {
        address partyAdmin;
        mapping(address => bool) accessRequests;
        mapping(address => bool) attendees;
    }

    struct AccessRequest {
        uint256 partyId;
        address user;
        bool approved;
    }

    address public superAdmin;
    mapping(address => bool) public partyAdmins;
    mapping(uint256 => Party) public parties;
    mapping(uint256 => AccessRequest[]) public accessRequests;

    constructor() {
        superAdmin = msg.sender;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Only the super admin can call this function");
        _;
    }

    modifier onlyPartyAdmin() {
        require(partyAdmins[msg.sender], "Only party admins can call this function");
        _;
    }

    function addPartyAdmin(address _admin) external onlySuperAdmin {
        partyAdmins[_admin] = true;
    }

    function removePartyAdmin(address _admin) external onlySuperAdmin {
        partyAdmins[_admin] = false;
    }

    function addParty(uint256 _partyId, address _admin) external onlyPartyAdmin {
        require(!partyExists(_partyId), "Party already exists");
        parties[_partyId].partyAdmin = _admin;
    }

    function partyExists(uint256 _partyId) internal view returns (bool) {
        return parties[_partyId].partyAdmin != address(0);
    }

    function requestAccess(uint256 _partyId) external {
        require(partyExists(_partyId), "Party does not exist");
        parties[_partyId].accessRequests[msg.sender] = true;
        accessRequests[_partyId].push(AccessRequest(_partyId, msg.sender, false));
    }

    function reviewAccessRequest(uint256 _partyId, address _user, bool _approved) external onlyPartyAdmin {
        require(partyExists(_partyId), "Party does not exist");
        require(parties[_partyId].accessRequests[_user], "Access request does not exist");

        parties[_partyId].accessRequests[_user] = false;

        if (_approved) {
            parties[_partyId].attendees[_user] = true;
            removeAccessRequest(_partyId, _user);
        } else {
            setAccessRequestApproval(_partyId, _user, false);
        }
    }

    function removeAccessRequest(uint256 _partyId, address _user) internal {
        AccessRequest[] storage requests = accessRequests[_partyId];
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].user == _user) {
                requests[i] = requests[requests.length - 1];
                requests.pop();
                break;
            }
        }
    }

    function setAccessRequestApproval(uint256 _partyId, address _user, bool _approved) internal {
        AccessRequest[] storage requests = accessRequests[_partyId];
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].user == _user) {
                requests[i].approved = _approved;
                break;
            }
        }
    }

    function revokeAccess(uint256 _partyId, address _user) external onlyPartyAdmin {
        require(partyExists(_partyId), "Party does not exist");
        require(parties[_partyId].attendees[_user], "User does not have access to the party");

        parties[_partyId].attendees[_user] = false;
    }

    function getAccessRequests(uint256 _partyId) external view returns (address[] memory) {
        AccessRequest[] storage requests = accessRequests[_partyId];
        uint256 pendingRequestCount = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            if (!requests[i].approved) {
                pendingRequestCount++;
            }
        }

        address[] memory pendingRequests = new address[](pendingRequestCount);
        uint256 index = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            if (!requests[i].approved) {
                pendingRequests[index] = requests[i].user;
                index++;
            }
        }

        return pendingRequests;
    }

    function isAttendee(uint256 _partyId, address _user) public view returns (bool) {
        return parties[_partyId].attendees[_user];
    }

    function hasAccessRequest(uint256 _partyId, address _user) public view returns (bool) {
        AccessRequest[] storage requests = accessRequests[_partyId];
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].user == _user) {
                return true;
            }
        }
        return false;
    }
}
