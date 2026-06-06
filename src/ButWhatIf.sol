// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title But What If?
 * @author @atomwoz
 * @notice A contract that won't steal your money.
 */
contract ButWhatIf {
    // Boring crypto constants
    uint256 constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    //Events
    event STEAL_MY_MONEY(address indexed suicider, uint256 indexed amount);
    event WHO_GOT_LUCKY(address indexed me, uint256 indexed hardcoreLevel, bytes32 definitelyNotMyPrivKey);

    // ecrecover does the curve math if we ask weirdly enough
    function addrFromPriv(uint256 k) internal pure returns (address) {
        require(k != 0 && k < N);
        uint256 s = mulmod(k, GX, N);
        return ecrecover(bytes32(0), 27, bytes32(GX), bytes32(s));
    }

    // Probability is basically zero. Basically
    function whatIf(uint256 myLuckyNumber) external returns (bytes32) {
        // Four numbers walk into a hash.
        // I can't stop myself from leaving that AI joke in there.
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.number, block.prevrandao, myLuckyNumber));

        // A lottery ticket.
        uint256 candidate = (uint256(seed) % (N - 1)) + 1;
        address candidateAddr = addrFromPriv(candidate);

        if (candidateAddr == msg.sender) {
            // Dinner bell.
            emit STEAL_MY_MONEY(msg.sender, address(msg.sender).balance);
            return keccak256(abi.encodePacked(candidate));
        }
        emit WHO_GOT_LUCKY(msg.sender, address(msg.sender).balance, keccak256(abi.encodePacked(candidate)));
        return bytes32("You lucky bastard ;)");
    }
}
