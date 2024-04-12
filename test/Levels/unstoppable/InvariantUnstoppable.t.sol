// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
//import {StdInvariant} from "forge-std/StdInvariant.sol";
import {UnstoppableHandler} from "./UnstoppableHandler.sol";

contract InvariantUnstoppable is Test {
    UnstoppableHandler handler;

    function setUp() public {
        handler = new UnstoppableHandler();
        targetContract(address(handler));
    }

    function invariant_unstoppable() public {
        assert(handler.invariant_checkFlashLoan());
    }
}
