pragma solidity ^0.5.0;

contract ProjectSubmission {
    // STEP 1
    address payable public owner;

    constructor() public {
      owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, 'Only the Contract Owner is authorized to perform this action');
      _;
    }

    struct University {
      bool available;
      address payable accountAddress;
      uint256 balance;
    }

    mapping (address => University) public universities;

    function registerUniversity(address payable universityAddress) public onlyOwner {
        require(universityAddress != address(0), 'University must have a deposit address');

        University memory newUniversity = University(true, universityAddress, 0);

        universities[universityAddress] = newUniversity;
    }

    function disableUniversity(address universityAddress) public onlyOwner {
        require(universityAddress != address(0), 'Must include a valid universityId');
        universities[universityAddress].available = false;
    }

    // STEP 2

    enum ProjectStatus { Waiting, Rejected, Approved, Disabled }

    struct Project {
        address payable author;
        address university;
        ProjectStatus status;
        uint256 balance;
    }

    mapping (bytes32 => Project) public projects;

    function submitProject(bytes32 documentHash, address payable universityAddress)
    public payable {
        require(universityAddress != address(0), 'universityAddress must be valid');
        require(universities[universityAddress].available, 'Selected University must be available');
        require(msg.value >= 1 ether, "Caller must send at least 1 ETH");

        Project memory newProject = Project(msg.sender, universityAddress, ProjectStatus.Waiting, 0);
        projects[documentHash] = newProject;

        ownerBalance += msg.value;
    }

    // STEP 3

    function disableProject(bytes32 documentHash) public onlyOwner {
        projects[documentHash].status = ProjectStatus.Disabled;
    }

    function reviewProject(bytes32 documentHash, uint status) public onlyOwner {
        require(status <= uint(ProjectStatus.Disabled), "Status must be valid");
        Project storage project = projects[documentHash];
        require(project.status == ProjectStatus.Waiting, "Can only approve Waiting projects");
        project.status = ProjectStatus(status);
    }

    // STEP 4

    uint public ownerBalance;

    function donate(bytes32 documentHash) public payable {
        Project storage project = projects[documentHash];
        require(project.status == ProjectStatus.Approved, "Project must have been already approved");

        uint256 valueToProject = msg.value * 7 / 10;
        uint256 valueToUniversity = msg.value * 2 / 10;
        uint256 valueToOwner = msg.value / 10;

        project.balance += valueToProject;
        universities[project.university].balance += valueToUniversity;
        ownerBalance += valueToOwner;
    }

    // STEP 5

    function withdraw() public {
        if (msg.sender == owner) {
            uint amount = ownerBalance;
            ownerBalance = 0;
            owner.transfer(amount);
        } else {
            University storage university = universities[msg.sender];
            uint amount = university.balance;
            university.balance = 0;
            university.accountAddress.transfer(amount);
        }
    }

    function withdraw(bytes32 documentHash) public {
        Project storage project = projects[documentHash];
        require(msg.sender == project.author, "Only project author can transfer");
        uint amount = project.balance;
        project.balance = 0;
        project.author.transfer(amount);
    }
}