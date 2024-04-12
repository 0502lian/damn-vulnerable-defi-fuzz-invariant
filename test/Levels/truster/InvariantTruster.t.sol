// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
//import {StdInvariant} from "forge-std/StdInvariant.sol";
import {TrusterHandler} from "./TrusterHandler.sol";

contract InvariantTruster is Test {
    TrusterHandler handler;

    function setUp() public {
        handler = new TrusterHandler();
        targetContract(address(handler));
    }

    function invariant_Truster() public {
        assert(handler.echidna_checkPoolBalance());
    }
}
