pragma solidity >=0.6.0 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";

contract LendingWallet {
    using SafeMath for uint;

    struct Borrower {
        uint totalBorrowed;
        uint allowance;
        address ownedAddress;
        bool isInitialised;
        bool isActive;
    }
    
    event Deposit(
        address indexed _from,
        uint _value
    );
    
    event Withdrawal(
        address indexed _to,
        uint _value
    );
    
    event BorrowerCreated(
        address indexed _address,
        uint _allowance
    );

    
    address private owner;
    uint public totalBalance;
    mapping(address => Borrower) private borrowers;
    
    constructor() public payable  {
        owner = msg.sender;
        
        if(msg.value > 0) {
            deposit(msg.value, msg.sender);
        }
    }
    
    function addNewBorrower(address _borrowerAddress, uint _allowance) public {
        require(msg.sender == owner, "Only the owner may add a new borrower");
        require(borrowers[_borrowerAddress].isInitialised == false, "This borrower has already been created");

        Borrower memory borrower = Borrower(
            0,
            _allowance,
            _borrowerAddress,
            true,
            true
        );
        
        borrowers[_borrowerAddress] = borrower;
        
        emit BorrowerCreated(_borrowerAddress, _allowance);
    }
    
    function getBorrower(address _address) public view returns(uint totalBorrowed, uint allowance) {
        return (borrowers[_address].totalBorrowed, borrowers[_address].allowance); 
    }
    
    function depositFunds() public payable {
        deposit(msg.value, msg.sender);
    }
    
    function withdrawFunds(uint _amount) public {
         if(msg.sender == owner) {
            withdraw(msg.sender, _amount);
            return;
        }

        withdrawForBorrower(msg.sender, _amount);
    }
    
    function withdrawForBorrower(address payable _address, uint _amount) private {
        Borrower memory borrower = borrowers[msg.sender];
        require(borrower.isInitialised, "Borrower has not been initialsed");
        require(borrower.isActive, "Borrower is not active");
        require(borrower.allowance > _amount, "Not enough allowance");
        require(borrower.allowance > borrower.totalBorrowed.add(_amount), "Will exceed total allowance");
        
        borrowers[msg.sender].totalBorrowed = borrower.totalBorrowed.add(_amount);
        withdraw(_address, _amount); 
    }
    
    function deposit(uint _amount, address _from) private {
        require(_amount > 0);
        
        totalBalance = totalBalance.add(_amount);
        emit Deposit(_from, _amount);
    }
    
    function withdraw(address payable _address, uint _amount) private {
        require(totalBalance >= _amount);
        _address.transfer(_amount);
        totalBalance = totalBalance.sub(_amount);

        emit Withdrawal(_address, _amount);
    }
}
