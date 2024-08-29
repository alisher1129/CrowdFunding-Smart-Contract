// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract CrowdFunding {
    mapping(address => uint256) public contributors;
    address public manager;
    uint256 public minimumContribution;
    uint256 public deadline;
    uint256 public target;
    uint256 public raiseAmount;
    uint256 public noOfContributors;

    struct Request {
        string description;
        address payable recipient;                           
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint256 => Request) public requests;
    uint256 public numRequest;

    constructor(uint256 _target, uint256 _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

     function setTargetAndDeadline(uint256 _target, uint256 _deadline) public onlyManager {
        target = _target;
        deadline = block.timestamp + _deadline;
    }

    function sendEth() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(
            msg.value >= minimumContribution,
            " Minimum Contribution is not met"
        );
        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] = contributors[msg.sender] + msg.value;
        raiseAmount = raiseAmount + msg.value;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public {
        require(
            block.timestamp > deadline && raiseAmount < target,
            "You are not eligible for refund "
        );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager can call this function");
        _;
    }

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyManager {
        Request storage newRequest = requests[numRequest];
        numRequest++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public  {
        require(contributors[msg.sender] > 0, "you must be contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false , "You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo)public  onlyManager{
        require(raiseAmount >= target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2, "Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
function getTotalRequests() public view returns (uint256) {
    return numRequest;
}
function getRequestDetails(uint256 _requestNo)
    public
    view
    returns (
        string memory description,
        address recipient,
        uint256 value,
        bool completed,
        uint256 noOfVoters
    )
{
    Request storage thisRequest = requests[_requestNo];
    return (
        thisRequest.description,
        thisRequest.recipient,
        thisRequest.value,
        thisRequest.completed,
        thisRequest.noOfVoters
    );
}



}
