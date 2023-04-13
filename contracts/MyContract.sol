// SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol";
import "woke/console.sol";

contract MyContract is AxelarExecutable {
    using AddressToString for address;

    event PayloadExecutionFailed(address recipient, bytes payload);

    struct TransferData {
        uint256 amount;
        address recipient;
        bytes payload;
    }

    constructor(address gateway_) AxelarExecutable(gateway_) {}

    function bridge(
        string calldata destinationChain,
        string calldata tokenSymbol,
        TransferData[] calldata data
    ) external {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i].amount;
        }

        IERC20 token = IERC20(gateway.tokenAddresses(tokenSymbol));
        token.transferFrom(msg.sender, address(this), sum);
        token.approve(address(gateway), sum);

        bytes memory payload = abi.encode(data);
        gateway.callContractWithToken(destinationChain, address(this).toString(), payload, tokenSymbol, sum);
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal override {
        TransferData[] memory data = abi.decode(payload, (TransferData[]));
        IERC20 token = IERC20(gateway.tokenAddresses(tokenSymbol));

        for (uint256 i = 0; i < data.length; i++) {
            TransferData memory transfer = data[i];
            token.transfer(transfer.recipient, transfer.amount);

            if (transfer.payload.length > 0) {
                (bool success, bytes memory ret) = transfer.recipient.call(transfer.payload);
                if (!success) {
                    emit PayloadExecutionFailed(transfer.recipient, transfer.payload);
                }
            }
        }
    }
}
