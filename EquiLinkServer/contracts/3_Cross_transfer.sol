// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IContract_router {
    function getRandomActiveIP() external  view returns (address[4] memory) ;
}
interface IContract_stake {
    function stakes(address) external view returns (address) ;
}


contract CrossTrans {
    IERC20 public token;
    address routerAddress;
    address burnaddr;
    //address抵押的余额
    mapping(address => uint256) public balances;
    //address抵押的validators的地址
    mapping(address => address) public validators;
    // 定义事件
    event test_TokensStaked(address indexed user, address toaddress, address valiIP, uint256 amount, bool status);
    event TokensStaked(address indexed user, address toaddress, address valiIP, address[4] randomIPs, uint256 amount, bool status);
    event CrossSuccess(address indexed user, uint256 amount, bool status);
    event CrossFail(address indexed user, uint256 amount, bool status);
    // constructor(address _tokenAddress) {
    constructor(address ERC20_tokenAddress,address _routerAddress) {
        token = IERC20(ERC20_tokenAddress);
        routerAddress = _routerAddress;
        burnaddr = ERC20_tokenAddress;
    }
    //测试能获取到转账
    // function StartCrossTrans(uint256 amount) public {
    // function StartCrossTrans(uint256 amount, address toaddr,address _validators) public {
    // MyContract 合约中的函数
    function executeTransfer(address from, address to, uint256 amount) public {
        require(token.transferFrom(from, to, amount), "Transfer failed");
    }
    function test_StartCrossTrans(uint256 amount, address toaddr) public {
    // 获取一个可用的 validators
        // IContract_router contractA = IContract_router(routerAddress);
        // address[4] memory randomIPs = contractA.getRandomActiveIP(); // 确保返回的大小为 4

        address validatorIP = 0x28E2B18A77C9968A74BAaC3cAEC4FFCFe195Ac62;  // 直接获取第二个有效地址

        // 直接将代币转账到验证者手里
        require(token.transferFrom(msg.sender, validatorIP, amount), "Transfer failed");

        // 更新用户信息
        balances[msg.sender] += amount;
        validators[msg.sender] = validatorIP;

        // 触发 TokensStaked 事件
        emit test_TokensStaked(msg.sender, toaddr, validatorIP, amount, true);
    }

    function StartCrossTrans(uint256 amount, address toaddr) public {
        //获取一个可用的validators
        IContract_router contractA = IContract_router(routerAddress);
        address[4] memory randomIPs = contractA.getRandomActiveIP();
        address validatorIP = randomIPs[1];
        //验证validators质押金额大于在交易的金额,这一步在getRandomActiveIP里完成了
        // 将代币转账到合约
        // bool status = token.transferFrom(msg.sender, address(this), amount);
        //授权token
        // token.approve(address(this), amount);
        // new将代币转账到验证者手里
        // require(token.transferFrom(msg.sender,validatorIP, amount), "Transfer failed");
        //测试一下
        bool status = token.transferFrom(msg.sender,address(this), amount);
        require(status, "Transfer failed");
        balances[msg.sender] += amount;
        validators[msg.sender] =validatorIP;
        // 触发 TokensStaked 事件
        emit TokensStaked(msg.sender, toaddr, validatorIP, randomIPs, amount, status);
    }

    function CrossTransactionSuccess(address sendaddr, uint256 amount) public {
        require(validators[sendaddr] == msg.sender, "Only the designated validator can perform this action");
        
        // 检查 sendaddr 的余额是否足够
        require(balances[sendaddr] >= amount, "Insufficient balance");
        
        // 将代币在链A burn
        ERC20Burnable(address(burnaddr)).burnFrom(msg.sender,amount);
        // ERC20Burnable(address(_tokenAddress)).burn(amount);
        // 更新 sendaddr 的余额
        balances[sendaddr] -= amount;

        // 触发 CrossSuccess 事件
        emit CrossSuccess(sendaddr, amount, true);
    }

    function CrossTransactionFail(address sendaddr, uint256 amount) public {
        require(validators[sendaddr] == msg.sender);
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        bool status = token.transferFrom(msg.sender, sendaddr, amount);
        require(status, "Transfer failed");
        // 触发 TokensUnstaked 事件
        emit CrossFail(msg.sender, amount, status);
    }

}
