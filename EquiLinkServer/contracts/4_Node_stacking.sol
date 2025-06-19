// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Staking
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */


contract StakingContract {
    address public admin; // 合约管理员

    struct Stake {
        uint256 amount; // 质押的金额
        bool isStaked;  // 是否质押
    }

    mapping(address => Stake) public stakes; // 记录每个地址的质押信息

    constructor() {
        admin = msg.sender; // 设置合约管理员
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier isStaking(address user) {
        require(stakes[user].isStaked, "User is not staking");
        _;
    }

    // 质押以太币
    function stake() public payable {
        require(msg.value > 0, "Stake amount must be greater than zero");
        require(!stakes[msg.sender].isStaked, "Already staking");

        stakes[msg.sender] = Stake({
            amount: msg.value,
            isStaked: true
        });
    }

    // 释放质押
    function unstake() external isStaking(msg.sender) {
        uint256 amount = stakes[msg.sender].amount;
        stakes[msg.sender].isStaked = false;
        stakes[msg.sender].amount = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw stake");
    }

    // 管理员没收质押
    function confiscate(address user) external onlyAdmin isStaking(user) {
        uint256 amount = stakes[user].amount;
        stakes[user].isStaked = false;
        stakes[user].amount = 0;

        // 将没收的资金转移到管理员地址
        (bool success, ) = admin.call{value: amount}("");
        require(success, "Failed to confiscate stake");
    }

    // 查询指定地址的质押金额
    function getStakeAmount(address user) external view returns (uint256) {
        return stakes[user].amount;
    }
}
