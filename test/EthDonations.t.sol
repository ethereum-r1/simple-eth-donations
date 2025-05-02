// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {EthDonations} from "../src/EthDonations.sol";
import {Ownable} from "@solady/contracts/auth/Ownable.sol";

contract EthDonationsTest is Test {
    EthDonations public d;
    address owner = 0xE73EaFBf9061f26Df4f09e08B53c459Df03E2b66;

    function setUp() public {
        d = new EthDonations(10 ether, block.timestamp + 90 days, owner);
        vm.deal(owner, 10 ether);
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
        d.claimDonations(address(0));

        vm.prank(owner);
        vm.expectRevert(EthDonations.DonationsGoalNotReached.selector);
        d.claimDonations(address(0));

        d.donate{value: 9 ether}();

        assertEq(address(d).balance, 10 ether);

        vm.expectRevert(EthDonations.DonationsNotEnded.selector);
        d.returnDonation();

        vm.warp(block.timestamp + 90 days);
        vm.expectRevert(EthDonations.DonationsGoalReached.selector);
        d.returnDonation();

        uint256 bal_before = owner.balance;

        vm.prank(owner);
        d.claimDonations(owner);

        assertEq(address(d).balance, 0);

        uint256 bal_after = owner.balance;
        assertEq(bal_after - bal_before, 10 ether);

        vm.prank(owner);
        vm.expectRevert(EthDonations.DonationsAlreadyClaimed.selector);
        d.claimDonations(address(0));

        vm.expectRevert(EthDonations.DonationsAlreadyClaimed.selector);
        d.donate{value: 1 ether}();

        vm.expectRevert(EthDonations.DonationsAlreadyClaimed.selector);
        d.returnDonation();
    }

    function test_ClaimDonationsEarly() public {
        d.donate{value: 1 ether}();

        vm.expectRevert(Ownable.Unauthorized.selector);
        d.claimDonations(address(0));

        vm.prank(owner);
        vm.expectRevert(EthDonations.DonationsGoalNotReached.selector);
        d.claimDonations(address(0));

        d.donate{value: 9 ether}();

        assertEq(address(d).balance, 10 ether);

        vm.expectRevert(EthDonations.DonationsNotEnded.selector);
        d.returnDonation();

        uint256 bal_before = owner.balance;

        vm.prank(owner);
        d.claimDonations(owner);

        assertEq(address(d).balance, 0);

        uint256 bal_after = owner.balance;
        assertEq(bal_after - bal_before, 10 ether);

        vm.prank(owner);
        vm.expectRevert(EthDonations.DonationsAlreadyClaimed.selector);
        d.claimDonations(address(0));

        vm.expectRevert(EthDonations.DonationsAlreadyClaimed.selector);
        d.donate{value: 1 ether}();

        vm.expectRevert(EthDonations.DonationsNotEnded.selector);
        d.returnDonation();

        vm.warp(block.timestamp + 90 days + 1);
        vm.expectRevert(EthDonations.DonationsAlreadyClaimed.selector);
        d.returnDonation();
    }

    function test_AddDonationsFor() public {
        d.donate{value: 1 ether}();
        address[] memory donors = new address[](2);
        donors[0] = address(1);
        donors[1] = address(this);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.expectRevert(Ownable.Unauthorized.selector);
        d.addDonationsFor(donors, amounts);

        vm.prank(owner);
        vm.expectRevert(EthDonations.NoDonation.selector);
        d.addDonationsFor(donors, amounts);

        vm.prank(owner);
        vm.expectRevert(EthDonations.AmountMismatch.selector);
        d.addDonationsFor{value: 1 ether}(donors, amounts);

        vm.prank(owner);
        vm.expectRevert(EthDonations.LengthMismatch.selector);
        address[] memory dummy_donors = new address[](3);
        d.addDonationsFor{value: 2 ether}(dummy_donors, amounts);
        vm.prank(owner);
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

        vm.prank(owner);

        vm.expectRevert(EthDonations.DonationsEnded.selector);
        d.addDonationsFor{value: 2 ether}(donors, amounts);
    }

    function test_Fallback() public {
        (bool success,) = address(d).call{value: 1 ether}("");
        assertEq(success, true);
        assertEq(d.donations(address(this)), 1 ether);

        (success,) = address(d).call{value: 1 ether}("aaaaaaaaaaaaaaaaaaaa");
        assertEq(success, true);
        assertEq(d.donations(address(this)), 2 ether);
    }

    receive() external payable {}
}
