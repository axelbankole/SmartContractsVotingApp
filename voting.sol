pragma solidity ^0.8.0;

contract VotingApp {
    // Struct to represent a voter
    struct Voter {
        bool registered;
        bool voted;
    }

    // Struct to represent a candidate
    struct Candidate {
        string name;
        uint votes;
    }

    // Mapping of addresses to voters
    mapping(address => Voter) public voters;

    // Array of candidates
    Candidate[] public candidates;

    // Modifier to check if the sender is registered and has not voted yet
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].registered, "You are not a registered voter.");
        require(!voters[msg.sender].voted, "You have already voted.");
        _;
    }

    // Constructor to initialize candidates
    constructor(string memory _candidate1, string memory _candidate2) {
        candidates.push(Candidate(_candidate1, 0));
        candidates.push(Candidate(_candidate2, 0));
    }

    // Function to register a voter
    function registerVoter() public {
        require(!voters[msg.sender].registered, "You are already registered.");
        // Additional age verification can be implemented here
        // For simplicity, we assume everyone is eligible to vote
        voters[msg.sender].registered = true;
    }

    // Function to cast a vote for a candidate
    function vote(uint _candidateIndex) public onlyRegisteredVoter {
        require(_candidateIndex < candidates.length, "Invalid candidate index.");
        voters[msg.sender].voted = true;
        candidates[_candidateIndex].votes++;
    }
.
    // Function to get the total votes for a candidate
    function getTotalVotes(uint _candidateIndex) public view returns (uint) {
        require(_candidateIndex < candidates.length, "Invalid candidate index.");
        return candidates[_candidateIndex].votes;
    }

    // Function to check if a voter has already voted
    function hasVoted() public view returns (bool) {
        return voters[msg.sender].voted;
    }

    // Function to check if a voter is registered
    function isRegistered() public view returns (bool) {
        return voters[msg.sender].registered;
    }
}
