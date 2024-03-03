// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "https://github.com/protofire/zeppelin-solidity/blob/master/contracts/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract EventManagement is ERC20,ReentrancyGuard {
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
    }

    address payable owner;
    uint256 counter;
    uint256 [] public eventNo;
    mapping (address => Event) public addressEvent;
    mapping (uint256 => Event) public numEvent;
    mapping (address => uint) public  idToEvent;
    mapping(uint256 => address[]) public registeredAddresses;

    constructor() ERC20 ("Vigor","VIG") {
        owner = payable(msg.sender);
        _mint(owner,100000);
    }

    function registerUser(string memory _name,gender _gender) external {
        user memory newUser;
        newUser.name = string(abi.encodePacked(_name));
        newUser.Gender = _gender;
    }
    

    function createEvent (string memory _location, uint256 _startTime, uint256 _duration,eventType _type,status _state,uint104 _amount) external {
        Event memory newEvent;
        newEvent.location = _location;
        newEvent.startTime = _startTime;
        newEvent.duration = _duration;
        newEvent.Type = _type;
        newEvent.state = _state;
        newEvent.amount = _amount;
        newEvent.eventOwner = payable (msg.sender);

        counter++;
        newEvent.eventID = counter;
        eventNo.push(newEvent.eventID);
        addressEvent[msg.sender] = newEvent;
        numEvent[newEvent.eventID] = newEvent;
        registeredAddresses[newEvent.eventID] = new address[](0);
    }
    
    function selectEvent(uint256 _counter) external payable{
        require(numEvent[_counter].state == status.waiting || numEvent[_counter].state == status.started, "Event ended");
        if (numEvent[_counter].Type == eventType.unPaid){
            idToEvent[msg.sender] = _counter;  
            registeredAddresses[_counter].push(msg.sender);
        }
        else {
            require(numEvent[_counter].amount == msg.value, "Enter the correct value");
               uint calc = msg.value * 2/10;
               owner.transfer(calc);
               numEvent[_counter].eventOwner.transfer(msg.value - calc);
               idToEvent[msg.sender] = _counter;  
               registeredAddresses[_counter].push(msg.sender);
        }
    }
    function getRegisteredAddresses(uint256 _eventID) external view returns (address[] memory) {
        return registeredAddresses[_eventID];
    }

    modifier onlyEventCreator (uint256 _eventID) {
        require(msg.sender == numEvent[_eventID].eventOwner,"you have not created an event");
        _;
    }
    
    function updateStatus(uint256 _eventID) external onlyEventCreator(_eventID) returns (uint256){
        Event storage currentEvent = numEvent[_eventID];
        uint256 endTime = currentEvent.startTime + currentEvent.duration;

        return block.timestamp;
        return currentEvent.startTime;
        return endTime;
        //return currentEvent.state;

        if (block.timestamp > endTime)
         {
            currentEvent.state = status.ended;
            emit ended("event ended");
        } 
        else if (block.timestamp < currentEvent.startTime)
        {
            currentEvent.state = status.waiting;
            emit waiting("waiting for the event to start");
        } 
        else 
        {
            currentEvent.state = status.started;
            emit started("event started");
        }
    }
}