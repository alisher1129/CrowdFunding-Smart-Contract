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
        address[] voterList; // New array to store the list of voters
    }
    mapping(uint256 => Request) public requests;
    uint256 public numRequest;

    //Mutex for Re-entrancy
    bool private locked;
    modifier nonReentrant() {
        require(!locked, "No re-entrancy Wait Please !");
        locked = true;
        _;
        locked = false;
    }

    bool private sendEthLocked;

    modifier nonReentrantSendEth() {
        require(!sendEthLocked, "No re-entrancy in sendEth!");
        sendEthLocked = true;
        _;
        sendEthLocked = false;
    }
    bool private voteLocked;

    modifier nonReentrantVote() {
        require(!voteLocked, "No re-entrancy in voteRequest!");
        voteLocked = true;
        _;
        voteLocked = false;
    }

 bool private createRequestLocked;

    modifier nonReentrantCreateRequest() {
        require(!createRequestLocked, "No re-entrancy in voteRequest!");
        createRequestLocked = true;
        _;
        createRequestLocked = false;
    }

bool private makePaymentLocked;

    modifier nonReentrantMakePaymentLocked() {
        require(!makePaymentLocked, "No re-entrancy in voteRequest!");
        makePaymentLocked = true;
        _;
        makePaymentLocked = false;
    }


    constructor(uint256 _target, uint256 _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function setTargetAndDeadline(uint256 _target, uint256 _deadline)
        public
        onlyManager
    {
        target = _target;
        deadline = block.timestamp + _deadline;
    }

    function sendEth(uint256 _amount) public nonReentrantSendEth payable  {
        require(block.timestamp < deadline, "Deadline has passed");
        require(
            _amount >= minimumContribution,
            " Minimum Contribution is not met"
        );
        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] = contributors[msg.sender] + _amount;
        raiseAmount += _amount;

    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public nonReentrant {
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
    ) public nonReentrantCreateRequest onlyManager {
        Request storage newRequest = requests[numRequest];
        numRequest++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint256 _requestNo) public nonReentrantVote{
        require(contributors[msg.sender] > 0, "you must be contributor");
        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted"
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
        thisRequest.voterList.push(msg.sender); // Add the voter's address to the list
    }

    function makePayment(uint256 _requestNo) public nonReentrantMakePaymentLocked onlyManager {
        require(raiseAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.completed == false,
            "The request has been completed"
        );
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "Majority does not support"
        );
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
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

    function getAllRequests()
        public
        view
        returns (
            uint256 totalRequests,
            uint256[] memory requestIds,
            string[] memory descriptions,
            address[] memory recipients,
            uint256[] memory values,
            bool[] memory completeds,
            uint256[] memory noOfVotersList
        )
    {
        totalRequests = numRequest;
        requestIds = new uint256[](numRequest);
        descriptions = new string[](numRequest);
        recipients = new address[](numRequest);
        values = new uint256[](numRequest);
        completeds = new bool[](numRequest);
        noOfVotersList = new uint256[](numRequest);

        for (uint256 i = 0; i < numRequest; i++) {
            Request storage thisRequest = requests[i];
            requestIds[i] = i; // Store the request number
            descriptions[i] = thisRequest.description;
            recipients[i] = thisRequest.recipient;
            values[i] = thisRequest.value;
            completeds[i] = thisRequest.completed;
            noOfVotersList[i] = thisRequest.noOfVoters;
        }

        return (
            totalRequests,
            requestIds,
            descriptions,
            recipients,
            values,
            completeds,
            noOfVotersList
        );
    }

    function getVoters(uint256 _requestNo)
        public
        view
        returns (address[] memory)
    {
        return requests[_requestNo].voterList;
    }
}
