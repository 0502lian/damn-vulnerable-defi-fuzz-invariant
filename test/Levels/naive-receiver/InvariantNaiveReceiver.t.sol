// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {NaiveReceiverHandler} from "./NaiveReceiverHandler.sol";

contract InvariantNaiveReceiver is Test {
    NaiveReceiverHandler handler;

    function setUp() public {
        deal(address(this), 1000_000 ether);
        handler = new NaiveReceiverHandler{value: 2000 ether}();

        targetContract(address(handler));
    }

    function invariant_NaiveReceiver() public {
        assert(handler.echidna_test_contract_balance());
    }
}
