// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EthDonations} from "../src/EthDonations.sol";
import {Ownable} from "@solady/contracts/auth/Ownable.sol";

contract EthDonationsTest is Test {
    EthDonations public d;

    function setUp() public {
        d = new EthDonations(10 ether, block.timestamp + 90 days, msg.sender);
    }

    function test_Donate() public {
        d.donate{value: 1 ether}();
        assertEq(d.donations(address(this)), 1 ether);

        vm.expectRevert(EthDonations.NoDonation.selector);
        d.donate();

        vm.expectRevert(EthDonations.DonationsEnded.selector);
        vm.warp(block.timestamp + 90 days + 1);
        d.donate{value: 1 ether}();
    }

    function test_ReturnDonation() public {
        uint256 starting_bal = address(this).balance;
        d.donate{value: 1 ether}();
        assertEq(d.donations(address(this)), 1 ether);

        vm.expectRevert(EthDonations.DonationsNotEnded.selector);
        d.returnDonation();

        vm.warp(block.timestamp + 90 days);
        d.returnDonation();
        assertEq(d.donations(address(this)), 0);
        assertEq(address(this).balance, starting_bal);

        vm.prank(address(1));
        vm.expectRevert(EthDonations.NoDonation.selector);
        d.returnDonation();
    }

    function test_ClaimDonations() public {
        d.donate{value: 1 ether}();

        vm.expectRevert(Ownable.Unauthorized.selector);
        d.claimDonations();

        vm.prank(d.owner());
        vm.expectRevert(EthDonations.DonationsNotEnded.selector);
        d.claimDonations();

        vm.warp(block.timestamp + 90 days);
        vm.prank(d.owner());
        vm.expectRevert(EthDonations.DonationsGoalNotReached.selector);
        d.claimDonations();

        d.donate{value: 9 ether}();

        assertEq(address(d).balance, 10 ether);

        vm.expectRevert(EthDonations.DonationsGoalReached.selector);
        d.returnDonation();

        uint256 bal_before = d.owner().balance;

        vm.prank(d.owner());
        d.claimDonations();

        assertEq(address(d).balance, 0);

        uint256 bal_after = d.owner().balance;
        assertEq(bal_after - bal_before, 10 ether);
    }

    function test_AddToDonations() public {
        d.donate{value: 1 ether}();
        address[] memory donors = new address[](2);
        donors[0] = address(1);
        donors[1] = address(this);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.expectRevert(Ownable.Unauthorized.selector);
        d.addDonationsFor(donors, amounts);

        vm.prank(d.owner());
        vm.expectRevert(EthDonations.NoDonation.selector);
        d.addDonationsFor(donors, amounts);

        vm.prank(d.owner());
        vm.expectRevert(EthDonations.AmountMismatch.selector);
        d.addDonationsFor{value: 1 ether}(donors, amounts);

        vm.prank(d.owner());
        vm.expectRevert(EthDonations.LengthMismatch.selector);
        address[] memory dummy_donors = new address[](3);
        d.addDonationsFor{value: 2 ether}(dummy_donors, amounts);
        vm.prank(d.owner());
        d.addDonationsFor{value: 2 ether}(donors, amounts);

        assertEq(d.donations(address(1)), 1 ether);
        assertEq(d.donations(address(this)), 2 ether);

        vm.warp(block.timestamp + 90 days + 1);

        vm.prank(address(1));
        uint256 bal_before = address(1).balance;
        d.returnDonation();
        uint256 bal_after = address(1).balance;
        assertEq(bal_after - bal_before, 1 ether);
        bal_before = address(this).balance;
        d.returnDonation();
        bal_after = address(this).balance;
        assertEq(bal_after - bal_before, 2 ether);

        vm.prank(d.owner());

        vm.expectRevert(EthDonations.DonationsEnded.selector);
        d.addDonationsFor{value: 2 ether}(donors, amounts);
    }

    receive() external payable {}
}
