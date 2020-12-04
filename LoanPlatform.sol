pragma solidity ^0.6.4;

contract SmartLoan {

  uint public loanAmount;
  uint public payableAmount;
  uint public timePeriod;
  uint public borrowerPayment;
  address payable public borrower;
  address payable public lender;
  BorrowerCollateral public collateral;
  uint public collateralAmount;
  uint public contractStart;
  uint public contractEnd;
  bool public loanAmountWithdrawn = false;
  bool public amountPaid = false;

  constructor(uint _loanAmount, uint _payableAmount, uint _timePeriod) public {
    loanAmount = _loanAmount;
    payableAmount = _payableAmount;
    timePeriod = _timePeriod;
    contractStart = 0;
    borrower = msg.sender;
  }

  fallback() payable external {
    require(
      msg.value == loanAmount,
      'REVERT: Contribution should be the requested amount.'
    );
    lender = msg.sender;
    contractStart = block.timestamp;
    uint timePeriodUnix = timePeriod * 60 * 60 * 24 * 30; // convert timePeriod to Unix time
    contractEnd = contractStart + timePeriodUnix;
  }

  function addCollateral(address payable collateralAddress) public returns(uint) {
    collateral = BorrowerCollateral(collateralAddress);
    collateralAmount = collateral.collateralAmount();
  }

  function withdrawLoanAmount() payable external {
    if(!loanAmountWithdrawn) {
      require(
      msg.sender == borrower,
      'REVERT: Only the borrower can withdraw the loan amount!'
      );
      msg.sender.transfer(loanAmount);
      loanAmountWithdrawn = true;
    } else {
      revert('REVERT: Loan amount already withdrawn!');
    }
  }

  function makeBorrowerPayment() payable external {
    require(
      msg.value == payableAmount,
      'REVERT: The payment should be the total amount payable!'
    );
    borrowerPayment = msg.value;
    amountPaid = true;
  }

  function withdrawBorrowerPayment() external {
    require(
      lender != address(0),
      'REVERT: Contract has not started, lender does not exist!'
    );
    require(
      msg.sender == lender,
      'REVERT: Only the lender can withdraw the payment!'
    );
    msg.sender.transfer(borrowerPayment);
  }
}


contract BorrowerCollateral {
  
  uint public collateralAmount;
  SmartLoan public loan;

  fallback() payable external {
    collateralAmount = msg.value;
  }

  function withdrawCollateral(address payable loanAddress) external {
    loan = SmartLoan(loanAddress);
    if(loan.contractStart() == 0){
      require(
        msg.sender == loan.borrower(),
        'REVERT: Only the borrower can withdraw the collateral before the contract starts!'
      );
      msg.sender.transfer(address(this).balance);
      collateralAmount = 0;
    } else if(block.timestamp < loan.contractEnd()){
      require(
        loan.amountPaid() == true,
        'REVERT: Collateral can\'t be withdrawn until the payment is made!'
      );
      require(
        msg.sender == loan.borrower(),
        'REVERT: Only the borrower can withdraw the collateral before the contract ends!'
      );
      msg.sender.transfer(address(this).balance);
      collateralAmount = 0;
    } else {
      require(
        msg.sender == loan.lender(),
        'REVERT: Payment is late; collateral forfeited to lender.'
      );
      msg.sender.transfer(address(this).balance);
      collateralAmount = 0;
    }
  }
}
