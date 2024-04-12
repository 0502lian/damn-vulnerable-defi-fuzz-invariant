pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {FlashLoanReceiver} from "../../../src/Contracts/naive-receiver/FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "../../../src/Contracts/naive-receiver/NaiveReceiverLenderPool.sol";

import "openzeppelin-contracts/utils/Address.sol";

contract NaiveReceiverHandler is Test {
    using Address for address payable;

    // We will send ETHER_IN_POOL to the flash loan pool.
    uint256 constant ETHER_IN_POOL = 1000e18;
    // We will send ETHER_IN_RECEIVER to the flash loan receiver.
    uint256 constant ETHER_IN_RECEIVER = 10e18;

    NaiveReceiverLenderPool pool;
    FlashLoanReceiver receiver;

    // Setup echidna test by deploying the flash loan pool and receiver and sending them some ether.
    constructor() payable {
        pool = new NaiveReceiverLenderPool();
        receiver = new FlashLoanReceiver(payable(address(pool)));
        payable(address(pool)).sendValue(ETHER_IN_POOL);
        payable(address(receiver)).sendValue(ETHER_IN_RECEIVER);
    }

    // We want to test whether the balance of the receiver contract can be decreased.
    function echidna_test_contract_balance() public view returns (bool) {
        console2.log("balance is:", address(receiver).balance);
        return address(receiver).balance >= 10 ether;
    }

    function flashloan(address borrower, uint256 borrowAmount) public {
        uint256 balance = address(pool).balance;
        borrowAmount = bound(borrowAmount, 0, balance);

        pool.flashLoan(borrower, borrowAmount);
    }
}
