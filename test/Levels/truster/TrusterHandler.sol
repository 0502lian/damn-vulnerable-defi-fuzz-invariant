// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../../src/Contracts/truster/TrusterLenderPool.sol";

contract TrusterHandler {
    DamnValuableToken public dvt;
    TrusterLenderPool public pool;
    address public attacker;

    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    constructor() payable {
        dvt = new DamnValuableToken();
        pool = new TrusterLenderPool(address(dvt));
        dvt.transfer(address(pool), TOKENS_IN_POOL);
        attacker = msg.sender;
    }

    function flashLoan(uint256 borrowAmount, address borrower, address target, bytes calldata data) public {
        pool.flashLoan(borrowAmount, borrower, target, data);
    }

    function transferFrom() public {
        uint256 amount = dvt.allowance(address(pool), attacker);
        if (amount > 0) {
            dvt.transferFrom(address(pool), attacker, amount);
        }
    }

    function echidna_checkPoolBalance() public returns (bool) {
        return dvt.balanceOf(address(pool)) >= TOKENS_IN_POOL;
    }
}
