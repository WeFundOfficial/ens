pragma solidity ^0.7.0;

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract FIFSRegistrar {
    address public ensAddress;
    bytes32 public rootNode;

    modifier onlyOwner(bytes32 label) {
        address currentOwner = Ens(ensAddress).owner(keccak256(abi.encodePacked(rootNode, label)));
        require(currentOwner == address(0x0) || currentOwner == msg.sender, "Only owner can call this");
        _;
    }

    constructor(address ensAddr, bytes32 node) {
        ensAddress = ensAddr;
        rootNode = node;
    }

    function register(bytes32 label, address owner) public onlyOwner(label) {
        Ens(ensAddress).setSubnodeOwner(rootNode, label, owner);
    }
}

/**
 * ENS interface
 */
interface Ens {
    function owner(bytes32 node) external view returns (address);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
}
