// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {UnstoppableLender} from "../../../src/Contracts/unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "../../../src/Contracts/unstoppable/ReceiverUnstoppable.sol";

/// @dev To run this contract: $ npx hardhat clean && npx hardhat compile --force && echidna-test . --contract UnstoppableEchidna --config contracts/unstoppable/config.yaml
contract UnstoppableHandler is Test {
    // We will send ETHER_IN_POOL to the flash loan pool.
    uint256 constant ETHER_IN_POOL = 1000000e18;
    // We will send INITIAL_ATTACKER_BALANCE to the attacker (which is the deployer) of this contract.
    uint256 constant INITIAL_ATTACKER_BALANCE = 100e18;

    DamnValuableToken token;
    UnstoppableLender pool;
    ReceiverUnstoppable receiverUnstoppable;

    // Setup echidna test by deploying the flash loan pool, approving it for token transfers, sending it tokens, and sending the attacker some tokens.
    constructor() {
        token = new DamnValuableToken();
        pool = new UnstoppableLender(address(token));

        receiverUnstoppable = new ReceiverUnstoppable(address(pool));
        token.approve(address(pool), ETHER_IN_POOL);
        pool.depositTokens(ETHER_IN_POOL);
        token.transfer(msg.sender, INITIAL_ATTACKER_BALANCE);
    }

    // We want to check whether flash loans can always be made.
    function invariant_checkFlashLoan() public returns (bool) {
        //pool.flashLoan(10);
        receiverUnstoppable.executeFlashLoan(10);

        return true;
    }

    function transferToken(uint256 amount) public {
        uint256 balance = token.balanceOf(address(this));
        amount = bound(amount, 0, balance);

        token.transfer(address(pool), amount);
    }

    function deposit(uint256 amount) public {
        uint256 balance = token.balanceOf(address(this));
        amount = bound(amount, 0, balance);
        if (amount > 0) {
            token.approve(address(pool), amount);
            pool.depositTokens(amount);
        }
    }
}
