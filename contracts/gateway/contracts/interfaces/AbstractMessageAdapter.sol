// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IMessageGateway.sol";

// adapter knows hot to send message to remote adapter.
abstract contract AbstractMessageAdapter {
    IMessageGateway public immutable localGateway;

    constructor(address _localGatewayAddress) {
        localGateway = IMessageGateway(_localGatewayAddress);
    }

    ////////////////////////////////////////
    // Abstract functions
    ////////////////////////////////////////
    // For receiving
    function allowedReceiving(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) internal virtual returns (bool);

    // For sending
    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal virtual returns (uint256);

    function estimateFee() external view virtual returns (uint256);

    function getRemoteAdapterAddress() public virtual returns (address);

    ////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////
    // called by local gateway
    function send(
        address _fromDappAddress,
        address _toDappAddress,
        bytes calldata _message
    ) external payable returns (uint256) {
        // check this is called by local gateway
        require(
            msg.sender == address(localGateway),
            "not allowed to be called by others except local gateway"
        );
        address remoteAdapterAddress = getRemoteAdapterAddress();
        require(remoteAdapterAddress != address(0), "remote adapter not set");

        return
            remoteExecute(
                // the remote adapter
                remoteAdapterAddress,
                // the call to be executed on remote adapter
                abi.encodeWithSignature(
                    "recv(address,address,bytes)",
                    _fromDappAddress,
                    _toDappAddress,
                    _message
                )
            );
    }

    // called by remote adapter through low level messaging contract
    function recv(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) external {
        require(
            allowedReceiving(_fromDappAddress, _toDappAddress, _message),
            "!allowedReceiving"
        );

        // call local gateway to receive message
        localGateway.recv(_fromDappAddress, _toDappAddress, _message);
    }
}
