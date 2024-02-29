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
        uint104 amount;
        uint256 eventID;
    }

    address payable owner;
    uint256 deduction;
    uint256 counter;
    uint256 [] eventNo;
    mapping (address => Event) public addressEvent;
    mapping (uint256 => Event) public numEvent;

    constructor() ERC20 ("Vigor","VIG") {
        owner = payable(msg.sender);
        _mint(owner,100000);
    }

    function registerUser(string memory _name,gender _gender) external pure {
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
        newEvent.eventOwner = msg.sender;

        counter++;
        newEvent.eventID = counter;
        eventNo.push(newEvent.eventID);
        addressEvent[msg.sender] = newEvent;
        numEvent[newEvent.eventID] = newEvent;
    }
    
    mapping (address => mapping(address => Event)) public eventAddress;
    mapping (uint => mapping(address => Event)) public addressNum;

    function selectEvent(uint256 _counter) external payable returns(string memory){
    for (uint i = 0; i < eventNo.length; i++){
        if (_counter == eventNo[i]){
            require(numEvent[i].state == status.waiting || numEvent[i].state == status.started,"event ended");
            addressNum[i][msg.sender] = numEvent[i];
            if(numEvent[i].Type == eventType.unPaid){
                addressNum[i][msg.sender] = numEvent[i]; 
                eventAddress[msg.sender][numEvent[i].eventOwner] = numEvent[i];
            }
            else{
                require(numEvent[i].amount == msg.value);
                uint calc = msg.value * 2/10;
                (owner).transfer(calc);
                (numEvent[i].eventOwner).transfer(msg.value - calc);
                addressNum[i][msg.sender] = numEvent[i]; 
                eventAddress[msg.sender][numEvent[i].eventOwner] = numEvent[i];
            }
            return "event selected";
        }
    }
    return "event not found";
}

    modifier onlyEventCreator {
        require(msg.sender == addressEvent[msg.sender].eventOwner,"you have not created an event");
        _;
    }
    
    function updateStatus() external  onlyEventCreator{

        if (addressEvent[msg.sender].duration > block.timestamp)
        {
            addressEvent[msg.sender].state = status.ended;
        }
        else if (addressEvent[msg.sender].duration < block.timestamp)
        {
            addressEvent[msg.sender].state = status.waiting;
        }
        else
        {
            addressEvent[msg.sender].state = status.started;
        }
    }
}