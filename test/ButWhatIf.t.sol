// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {ButWhatIf} from "../src/ButWhatIf.sol";

contract ButWhatIfTest is Test {
    ButWhatIf public target;

    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    event STEAL_MY_MONEY(address indexed suicider, uint256 indexed amount);
    event WHO_GOT_LUCKY(address indexed me, uint256 indexed hardcoreLevel, bytes32 definitelyNotMyPrivKey);

    function setUp() public {
        target = new ButWhatIf();
    }

    function test_HappyPath_ReturnsLuckyBastardAndWhoGotLuckyEventForRandomCaller() public {
        address caller = address(0xBEEF);
        uint256 my_lucky_number = 7;
        vm.deal(caller, 123 wei);

        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.number, block.prevrandao, my_lucky_number));
        uint256 candidate = (uint256(seed) % (N - 1)) + 1;

        vm.expectEmit(true, true, false, true, address(target));
        emit WHO_GOT_LUCKY(caller, caller.balance, keccak256(abi.encodePacked(candidate)));

        vm.prank(caller);
        bytes32 result = target.whatIf(my_lucky_number);

        assertEq(result, bytes32("You lucky bastard ;)"));
    }

    function test_ExtractionPath_AttackerReconstructsSeedAndHijacks() public {
        // seed is composed entirely of public block fields — anyone can compute it offchain
        uint256 ts = 1_700_000_000;
        uint256 num = 42;
        bytes32 prevrandao = bytes32(uint256(0xDEAD));
        uint256 my_lucky_number = 13;

        vm.warp(ts);
        vm.roll(num);
        vm.prevrandao(prevrandao);

        bytes32 seed = keccak256(abi.encodePacked(ts, num, prevrandao, my_lucky_number));
        uint256 candidate = (uint256(seed) % (N - 1)) + 1;

        address victim = vm.addr(candidate);
        vm.deal(victim, 1 ether);

        vm.expectEmit(true, true, false, true, address(target));
        emit STEAL_MY_MONEY(victim, victim.balance);

        vm.prank(victim);
        bytes32 result = target.whatIf(my_lucky_number);

        assertEq(result, keccak256(abi.encodePacked(candidate)));
    }
}
