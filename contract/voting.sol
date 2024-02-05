// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// Déclaration du contrat "Voting"
contract Voting {

    // Adresse du propriétaire du contrat
    address public owner;

    // Solde initial pour le compte administrateur
    uint accountAdmin = 100 ether;

    // Total des fonds recueillis
    uint public totalWallet;

    // Liste des adresses des votants
    address[] public votersAddresses;

    // Statut des votants (true s'ils ont voté, false sinon)
    mapping(address => bool) public statutVoters;

    // Timestamp du début et de la fin des votes
    uint public votingStart;
    uint public votingEnd;

    // Mot de passe administrateur (à remplacer par des pratiques de sécurité appropriées)
    string private adminPassword = "your_password";

    // Structure représentant les informations d'un votant
    struct Votant {
        string username;
        uint choice;
        bool voted;
        uint accountWallet;
    }

    // Structure représentant les informations d'un votant pour affichage public
    struct VoterInfo {
        string username;
        bool voted;
        uint account;
    }
    
    // Mapping des votants
    mapping(address => Votant) public voters;

    // Événement émis lors de l'affichage des résultats
    event ResultsDisplayed(uint winner, uint votesForWinner, uint votesForLoser);

    // Événement émis lors de l'inscription d'un nouveau votant
    event NewVoter(address indexed voterAddress);

    // Constructeur du contrat
    constructor() {
        // L'adresse du déploieur du contrat devient le propriétaire
        owner = msg.sender;
    }

    // Fonction pour définir l'heure de début des votes
    function setVotingStartTime(uint _startTime) external onlyAdminPassword(adminPassword) {
        votingStart = _startTime + 28800; // Ajoute 8 heures pour convertir en timestamp UNIX
    }

    // Fonction pour définir l'heure de fin des votes
    function setVotingEndTime() external onlyAdminPassword(adminPassword) {
        votingEnd = votingStart; // À des fins d'exemple, il faudrait ajuster cela correctement
    }

    // Modificateur pour n'autoriser que l'administrateur à appeler une fonction
    modifier onlyAdmin() {
        require(msg.sender == owner, "Seul l'administrateur peut appeler cette fonction");
        _;
    }

    // Modificateur pour n'autoriser que l'administrateur avec le bon mot de passe
    modifier onlyAdminPassword(string memory _password) {
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(adminPassword)), "Mot de passe administrateur incorrect");
        _;
    }

    // Modificateur pour n'autoriser que le propriétaire à appeler une fonction
    modifier onlyOwner() {
        require(msg.sender == owner, "Seul le propriétaire peut appeler cette fonction");
        _;
    }

    // Fonction pour définir un nouveau mot de passe administrateur
    function setAdminPassword(string memory _newPassword) public onlyOwner {
        adminPassword = _newPassword;
    }

    // Fonction interne pour recharger le compte administrateur
    function rechargeAccountAdmin() internal onlyAdmin {
        require(address(this).balance <= 100 ether, "Solde insuffisant dans accountAdmin");
        payable(owner).transfer(100 ether);
    }

    // Fonction pour obtenir les informations des votants pour affichage public
    function getVotersInfo() external view returns (VoterInfo[] memory) {
        VoterInfo[] memory votersInfo = new VoterInfo[](votersAddresses.length);

        for (uint i = 0; i < votersAddresses.length; i++) {
            address voterAddress = votersAddresses[i];
            votersInfo[i] = VoterInfo({
                username: voters[voterAddress].username,
                voted: voters[voterAddress].voted,
                account: voters[voterAddress].accountWallet
            });
        }

        return votersInfo;
    }

    // Fonction pour enregistrer un nouveau votant
    function registerVoter(string memory _username) external onlyAdminPassword(adminPassword) {
        require(keccak256(abi.encodePacked(voters[msg.sender].username)) != keccak256(abi.encodePacked(_username)), "Le votant existe");
        require(statutVoters[msg.sender] == false, "Le votant a voté");

        voters[msg.sender] = Votant(_username, 0, false, 3 ether);
        statutVoters[msg.sender] = false;
        votersAddresses.push(msg.sender);

        require(accountAdmin >= 1 ether, "Solde insuffisant dans accountAdmin");
        accountAdmin -= 1 ether;

        emit NewVoter(msg.sender);
    }

    // Fonction pour obtenir l'adresse d'un votant en fonction de son nom d'utilisateur
    function getAddressByUsername(string memory _username) internal view returns (address) {
        for (uint i = 0; i < votersAddresses.length; i++) {
            address voterAddress = votersAddresses[i];
            if (keccak256(abi.encodePacked(voters[voterAddress].username)) == keccak256(abi.encodePacked(_username))) {
                return voterAddress;
            }
        }
        revert("Utilisateur non trouvé");
    }

    // Fonction pour vérifier le login d'un votant
    function login(string memory _username) public view returns (bool, string memory) {
        address voterAddress;
        bool usernameExists = false;

        for (uint i = 0; i < votersAddresses.length; i++) {
            if (keccak256(abi.encodePacked(voters[votersAddresses[i]].username)) == keccak256(abi.encodePacked(_username))) {
                voterAddress = votersAddresses[i];
                usernameExists = true;
                break;
            }
        }

        if (!usernameExists) {
            return (false, "Le votant n'existe pas");
        }

        return (true, "Identification réussie");
    }

    // Fonction pour obtenir le pourcentage de votants
    function getVotingPercentage() public view returns (uint) {
        uint totalVoters = votersAddresses.length;

        if (totalVoters == 0) {
            return 0; // Éviter la division par zéro
        }

        uint votedVoters = 0;
        
        for (uint i = 0; i < totalVoters; i++) {
            if (voters[votersAddresses[i]].voted) {
                votedVoters++;
            }
        }

        uint votingPercentage = (votedVoters * 100) / totalVoters;

        return votingPercentage;
    }

    // Événement pour notifier du pourcentage de votants
    event VotingPercentage(uint percentage);

    // Fonction pour que les votants enregistrent leur choix
    function votingByUsername(string memory _username, uint _choice) external payable {
        address voterAddress = getAddressByUsername(_username);
        (bool loginSuccess, ) = login(_username);
        require(loginSuccess, "Connexion requise avant de voter");

        require(voters[voterAddress].accountWallet >= 1 ether && voters[voterAddress].accountWallet - 1 ether >= 0, "Solde insuffisant dans accountWallet");
        require(!statutVoters[voterAddress], "Vous avez déjà voté");
        require(voters[voterAddress].choice == 0, "Vote déjà enregistré");

        statutVoters[voterAddress] = true;
        voters[voterAddress].choice = _choice;
        voters[voterAddress].voted = true;

        voters[voterAddress].accountWallet -= 1 ether;
        totalWallet += 1 ether;

        uint votingPercentage = getVotingPercentage();
        emit VotingPercentage(votingPercentage);
    }

    // Fonction pour obtenir le total des fonds recueillis
    function getTotalWallet() external view returns (uint) {
        return totalWallet;
    }

    // Fonction pour obtenir le gagnant des votes
    function getWinner() public view returns(uint winner, uint votesForWinner, uint votesForLoser){
        uint countChoice1 = 0;
        uint countChoice2 = 0;

        for (uint i = 0; i < votersAddresses.length; i++) {
            address voter = votersAddresses[i];
            if (voters[voter].choice == 1) {
                countChoice1++;
            } else if (voters[voter].choice == 2) {
                countChoice2++;
            }
        }

        if (countChoice1 > countChoice2) {
            return (1, countChoice1, countChoice2);
        } else if (countChoice2 > countChoice1) {
            return (2, countChoice2, countChoice1);
        } else {
            return (0, countChoice1, countChoice2); // Égalité
        }
    }

    // Fonction pour afficher les résultats (nécessite le mot de passe administrateur)
    function displayResults() external onlyAdminPassword(adminPassword) {
        (uint winner, uint votesForWinner, uint votesForLoser) = getWinner();
        emit ResultsDisplayed(winner, votesForWinner, votesForLoser);
    }
}