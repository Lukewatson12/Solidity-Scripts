pragma solidity >=0.6.0 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";

contract LendingWallet is AccessControl {
    using SafeMath for uint;
    
    modifier onlyAdminRole () {
      require(isAdmin(), "Not administrator");
      _;
    }

    modifier canWithdraw () {
      require(isAdmin() || isInitalised(), "Not permitted to withdraw");
      _;
    }

    struct Borrower {
        uint totalBorrowed;
        uint allowance;
        address ownedAddress;
        bool isInitialised;
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

    
    uint public totalBalance;
    mapping(address => Borrower) private borrowers;
    
    constructor() public payable {
       _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        if(msg.value > 0) {
            deposit(msg.value, msg.sender);
        }
    }
    
    function isAdmin() private view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function isInitalised() private view returns (bool) {
        return (borrowers[msg.sender].isInitialised);
    }

    function addNewBorrower(address _borrowerAddress, uint _allowance) public onlyAdminRole {
        require(borrowers[_borrowerAddress].isInitialised == false, "This borrower has already been created");

        Borrower memory borrower = Borrower(
            0,
            _allowance,
            _borrowerAddress,
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
         if(isAdmin()) {
            withdraw(msg.sender, _amount);
            return;
        }

        withdrawForBorrower(msg.sender, _amount);
    }
    
    function withdrawForBorrower(address payable _address, uint _amount) private canWithdraw {
        Borrower memory borrower = borrowers[msg.sender];
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
