// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "@solady/contracts/auth/Ownable.sol";

contract EthDonations is Ownable {
    error DonationsEnded();
    error DonationsNotEnded();
    error NoDonation();
    error TransferFailed();
    error DonationsGoalReached();
    error DonationsGoalNotReached();
    error DonationsAlreadyClaimed();
    error LengthMismatch();
    error AmountMismatch();

    event Donation(address indexed donor, uint256 amount);

    uint256 public immutable donationsGoal;
    uint256 public immutable donationsEndTime;

    mapping(address => uint256) public donations;
    bool public claimed;

    constructor(uint256 _donationsGoal, uint256 _donationsEndTime, address _owner) {
        donationsGoal = _donationsGoal;
        donationsEndTime = _donationsEndTime;
        _initializeOwner(_owner);
    }

    function donate() public payable {
        if (block.timestamp > donationsEndTime) revert DonationsEnded();
        if (claimed) revert DonationsAlreadyClaimed();
        if (msg.value == 0) revert NoDonation();
        donations[msg.sender] += msg.value;

        emit Donation(msg.sender, msg.value);
    }

    function returnDonation() external {
        if (block.timestamp < donationsEndTime) revert DonationsNotEnded();
        if (address(this).balance >= donationsGoal) revert DonationsGoalReached();
        if (claimed) revert DonationsAlreadyClaimed();

        uint256 amount = donations[msg.sender];
        if (amount == 0) revert NoDonation();
        donations[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function claimDonations(address recipient) external onlyOwner {
        if (claimed) revert DonationsAlreadyClaimed();
        uint256 amount = address(this).balance;
        if (amount < donationsGoal) revert DonationsGoalNotReached();

        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();

        claimed = true;
    }

    function addDonationsFor(address[] calldata donors, uint256[] calldata amounts) external payable onlyOwner {
        if (msg.value == 0) revert NoDonation();
        if (block.timestamp > donationsEndTime) revert DonationsEnded();
        if (claimed) revert DonationsAlreadyClaimed();

        uint256 length = donors.length;
        if (donors.length != amounts.length) revert LengthMismatch();

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < length; i++) {
            totalAmount += amounts[i];
            donations[donors[i]] += amounts[i];
            emit Donation(donors[i], amounts[i]);
        }

        if (totalAmount != msg.value) revert AmountMismatch();
    }

    receive() external payable {
        donate();
    }

    fallback() external payable {
        donate();
    }
}
