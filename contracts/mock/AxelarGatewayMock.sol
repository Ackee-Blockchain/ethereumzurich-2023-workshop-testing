// SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/ERC20MintableBurnable.sol";
import "woke/console.sol";

contract AxelarGatewayMock is IAxelarGateway {
    mapping(string => address) public tokenAddresses;

    function registerToken(ERC20MintableBurnable token) external {
        tokenAddresses[token.symbol()] = address(token);
    }

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external {
        ERC20MintableBurnable(tokenAddresses[symbol]).burn(msg.sender, amount);
        emit TokenSent(msg.sender, destinationChain, destinationAddress, symbol, amount);
    }

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external {
        emit ContractCall(msg.sender, destinationChain, contractAddress, keccak256(payload), payload);
    }

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external {
        ERC20MintableBurnable(tokenAddresses[symbol]).burn(msg.sender, amount);
        emit ContractCallWithToken(msg.sender, destinationChain, contractAddress, keccak256(payload), payload, symbol, amount);
    }

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool) {
        return true;
    }

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool) {
        return true;
    }

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool) {
        return true;
    }

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool) {
        ERC20MintableBurnable(tokenAddresses[symbol]).mint(msg.sender, amount);
        return true;
    }

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address) {
        return address(0);
    }

    function tokenDeployer() external view returns (address) {
        return address(0);
    }

    function tokenMintLimit(string memory symbol) external view returns (uint256) {
        return type(uint256).max;
    }

    function tokenMintAmount(string memory symbol) external view returns (uint256) {
        return 0;
    }

    function allTokensFrozen() external view returns (bool) {
        return false;
    }

    function implementation() external view returns (address) {
        return address(this);
    }

    function tokenFrozen(string memory symbol) external view returns (bool) {
        return false;
    }

    function isCommandExecuted(bytes32 commandId) external view returns (bool) {
        return false;
    }

    function adminEpoch() external view returns (uint256) {
        return 0;
    }

    function adminThreshold(uint256 epoch) external view returns (uint256) {
        return 0;
    }

    function admins(uint256 epoch) external view returns (address[] memory) {
        return new address[](0);
    }

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external {}

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external {}

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external {}

    function execute(bytes calldata input) external {}
}