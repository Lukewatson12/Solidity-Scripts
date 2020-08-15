pragma solidity >=0.6.0 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";


contract Allowance is AccessControl {
    struct AllowanceStruct {
        uint allowanceUsed;
        uint allowanceTotal;
        address ownedAddress;
        bool isInitialised;
    }
    
    event AllowanceCreated(
        address indexed _address,
        uint _allowance
    );
    
    mapping(address => AllowanceStruct) internal allowances;
    
    modifier onlyAdminRole () {
      require(isAdmin(), "Not administrator");
      _;
    }

    modifier canWithdraw () {
      require(isAdmin() || isInitalised(), "Not permitted to withdraw");
      _;
    }

    function isAdmin() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function isInitalised() private view returns (bool) {
        return (allowances[msg.sender].isInitialised);
    }
    
    function addNewAllowance(address _allowanceAddress, uint _allowance) public onlyAdminRole {
        require(allowances[_allowanceAddress].isInitialised == false, "This account has already been enabled");

        AllowanceStruct memory allowance = AllowanceStruct(
            0,
            _allowance,
            _allowanceAddress,
            true
        );
        
        allowances[_allowanceAddress] = allowance;
        
        emit AllowanceCreated(_allowanceAddress, _allowance);
    }
    
    function getBorrower(address _address) public view returns(uint totalUsed, uint allowanceTotal) {
        return (allowances[_address].allowanceUsed, allowances[_address].allowanceTotal); 
    }
}

contract LendingWallet is Allowance {
    using SafeMath for uint;
    
    event FundsDeposited(
        address indexed _from,
        uint _value
    );
    
    event FundsWithdrawn(
        address indexed _to,
        uint _value
    );
    
    constructor () public {
       _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function viewBalance() view public returns(uint) {
        return address(this).balance;
    }
    
    function withdrawFunds(uint _amount) public {
         if(Allowance.isAdmin()) {
            withdraw(msg.sender, _amount);
            return;
        }

        withdrawForBorrower(msg.sender, _amount);
    }
    
    function withdrawForBorrower(address payable _address, uint _amount) private canWithdraw {
        AllowanceStruct memory allowance = Allowance.allowances[msg.sender];
        require(allowance.allowanceTotal > _amount, "Not enough allowance");
        require(allowance.allowanceTotal >= allowance.allowanceUsed.add(_amount), "Will exceed total allowance");
        
        Allowance.allowances[msg.sender].allowanceUsed = allowance.allowanceUsed.add(_amount);
        withdraw(_address, _amount); 
    }
    
    function withdraw(address payable _address, uint _amount) private {
        require(address(this).balance >= _amount);
        _address.transfer(_amount);
        emit FundsWithdrawn(_address, _amount);
    }
}
