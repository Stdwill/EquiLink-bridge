// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
//8.14已修改，
/**
 * @title IPManager
 * @dev Store & retrieve IP addresses as Ethereum addresses
 */
 //获取validator的质押金额
interface IContractStake  {
    function getStakeAmount(address) external view returns (uint256);
}
 //获取validator的交易token金额总额
interface IContractTransfer  {
    function balances(address) external  view returns (uint256) ;
}
//要求validator的staking> 持有的token
//因为1和3合约相互依赖，先部署1合约，3合约地址在1运行时输入。

contract RouterManager is Ownable{
    address stakeContract;
    address public transferContract;
    //部署合约的是owner
    constructor(address _stakeAddr) Ownable(msg.sender) {
        stakeContract = _stakeAddr;
    }
    struct IPAddress {
        address ip;
        bool isActive;
    }
    uint256 ganacheSpecCount=0;
    uint256 private lastSelectedIndex; // Track the last selected index
    IPAddress[] public ipAddresses;

    mapping(address => uint256) private ipIndex;

    // event IPAdded(address ip);
    event IPStatusChanged(address ip, bool isActive);
    function settransferContractAddress(address _contractBAddress) external {
        transferContract = _contractBAddress;
    }
    function addIP(address ip) public onlyOwner {
        require(ipIndex[ip] == 0 && (ipAddresses.length == 0 || ipAddresses[0].ip != ip), "IP already exists");
        ipAddresses.push(IPAddress(ip, true));
        ipIndex[ip] = ipAddresses.length;
        // emit IPAdded(ip);
    }

    function setActiveStatus(address ip, bool isActive) public {
        uint256 index = ipIndex[ip];
        require(index > 0, "IP not found");
        ipAddresses[index - 1].isActive = isActive;
        emit IPStatusChanged(ip, isActive);
    }
    function getRandomActiveIP() external view returns (address[] memory) {
        require(ipAddresses.length >= 4, "Not enough IP addresses registered");

        // 使用数组存储前 4 个 active 的 IP 地址
        address[] memory selectedIPs = new address[](4);  // Declare and define `selectedIPs` here
        uint256 selectedCount = 0;
 
        // 按顺序选择前 4 个 `isActive` 的 IP 地址
        for (uint256 i = 0; i < ipAddresses.length && selectedCount < 4; i++) {
            if (ipAddresses[i].isActive) {
                selectedIPs[selectedCount] = ipAddresses[i].ip;
                selectedCount++;
            }
        }

        require(selectedCount == 4, "Not enough active IPs available");
        return selectedIPs;
    }


    // function getRandomActiveIP() external view returns (address[] memory) {
    //     require(ipAddresses.length > 0, "No IP addresses registered");

    //     uint256 activeCount = 0;
    //     for (uint256 i = 0; i < ipAddresses.length; i++) {
    //         if (ipAddresses[i].isActive) {
    //             activeCount++;
    //         }
    //     }
    //     require(activeCount >= 4, "Not enough active IPs available");

    //     uint256 selectedCount = 0;
    //     bool[] memory selected = new bool[](ipAddresses.length);
    //     address[] memory selectedIPs = new address[](4);  // Declare and define `selectedIPs` here


    //     while (selectedCount < 4) {
    //         uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, selectedCount))) % ipAddresses.length;
    //         //第一个是validator
    //         if (ipAddresses[randomNumber].isActive && !selected[randomNumber] && selectedCount == 0) {
    //             address validator = ipAddresses[randomNumber].ip;
    //             uint256 stakeAmount = IContractStake(stakeContract).getStakeAmount(validator);
    //             uint256 tokenBalance = IContractTransfer(transferContract).balances(validator);

    //             if (stakeAmount > tokenBalance) {
    //                 selectedIPs[selectedCount] = validator;  // Assign the value to `selectedIPs` here
    //                 selected[randomNumber] = true;
    //                 selectedCount++;
    //             }
    //         }
    //         //后续是watchtower
    //         if (ipAddresses[randomNumber].isActive && !selected[randomNumber] && selectedCount > 0) {
    //             address validator = ipAddresses[randomNumber].ip;
    //             selectedIPs[selectedCount] = validator;  // Assign the value to `selectedIPs` here
    //             selected[randomNumber] = true;
    //             selectedCount++;
    //         }
    //     }
        
    //     return selectedIPs;
    // }

}
