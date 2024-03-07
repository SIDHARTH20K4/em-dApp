// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFTcontract.sol";

contract EventManagement is ERC20,ReentrancyGuard{
    NFTContract public nftContract;
    struct user {
        string name;
        uint256 tokenCount;
        gender Gender;
        uint256 registrationTime;
    }

    event started(string);
    event ended(string);
    event waiting(string);

    enum gender {male,female}
    enum eventType {unPaid,Paid}
    enum status {waiting,started,ended}

    struct Event {
        string location;
        uint256 startTime;
        uint256 duration;
        eventType Type;
        status state;
        address payable eventOwner;
        uint256 amount;
        uint256 eventID;
        uint tokenID;
        string img;
    }

    uint private tokenID;
    address payable owner;
    uint256 counter;
    uint256 [] public eventNo;
    mapping (address => Event) public addressEvent;
    mapping (uint256 => Event) public numEvent;
    mapping (address => uint) public  idToEvent;
    mapping(uint256 => address[]) public registeredAddresses;
    user[] public Users;

    constructor()  ERC20("Migor","Mig") {
        owner = payable(msg.sender);
        _mint(owner,100000);
        nftContract = new NFTContract(); // Creating a new instance of your ERC721 contract
    }

    function registerUser(string memory _name,gender _gender) external{
        user memory newUser;
        newUser.name = string(abi.encodePacked(_name));
        newUser.Gender = _gender;
        Users.push(newUser);
    }
    

    function createEvent (
        string memory _location, 
        uint256 _startTime, 
        uint256 _duration,eventType _type,
        status _state,
        uint104 _amount,
        string calldata _img
        ) 
        external 
        {
        Event memory newEvent;
        newEvent.location = _location;
        newEvent.startTime = _startTime;
        newEvent.duration = _duration;
        newEvent.Type = _type;
        newEvent.state = _state;
        newEvent.amount = _amount;
        newEvent.eventOwner = payable (msg.sender);
        newEvent.img = _img;

        counter++;
        newEvent.eventID = counter;
        eventNo.push(newEvent.eventID);
        addressEvent[msg.sender] = newEvent;
        numEvent[newEvent.eventID] = newEvent;
        registeredAddresses[newEvent.eventID] = new address[](0);
    }
    
    function selectEvent(uint256 _counter) external payable nonReentrant{
        require(numEvent[_counter].state == status.waiting || numEvent[_counter].state == status.started, "Event ended");
        if (numEvent[_counter].Type == eventType.unPaid){
            idToEvent[msg.sender] = _counter;  
            registeredAddresses[_counter].push(msg.sender);
            transferFrom(owner, msg.sender, 5);
            tokenID++;
            nftContract.mint(msg.sender,tokenID,numEvent[_counter].img);
        }
        else {
            require(numEvent[_counter].amount == msg.value, "Enter the correct value");
               uint calc = msg.value * 2/10;
               owner.transfer(calc);
               numEvent[_counter].eventOwner.transfer(msg.value - calc);
               idToEvent[msg.sender] = _counter;  
               registeredAddresses[_counter].push(msg.sender);
               transferFrom(owner, msg.sender, 10);
               tokenID++;
               nftContract.mint(msg.sender,tokenID,numEvent[_counter].img);
        }
    }
    function getRegisteredAddresses(uint256 _eventID) external view returns (address[] memory) {
        return registeredAddresses[_eventID];
    }

    modifier onlyEventCreator (uint256 _eventID) {
        require(msg.sender == numEvent[_eventID].eventOwner,"you have not created an event");
        _;
    }

    function startEvent(uint256 _eventID) external  onlyEventCreator(_eventID){
        require(block.timestamp > numEvent[_eventID].startTime);
        numEvent[_eventID].state = status.started;
        emit started("event started");
    }

    function endEvent(uint256 _eventID) external  onlyEventCreator(_eventID){
        require(block.timestamp > numEvent[_eventID].startTime + numEvent[_eventID].duration);
        numEvent[_eventID].state = status.ended;
        emit ended("event ended");
    }

    // function updateStatus(uint256 _eventID) external onlyEventCreator(_eventID){
    //     if(block.timestamp > numEvent[_eventID].startTime){
    //         startEvent(_eventID);
    //     }
    //     else if (block.timestamp < numEvent[_eventID].startTime){
    //         waitEvent(_eventID);
    //     }
    //     else {
    //         endEvent(_eventID);
    //     }
    // }
}