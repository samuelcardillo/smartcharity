// SPDX-License-Identifier: MIT

/*
      ____  _     ____  ____  _  _____ ___  _
    /   _\/ \ /|/  _ \/  __\/ \/__ __\\  \//
    |  /  | |_||| / \||  \/|| |  / \   \  / 
    |  \__| | ||| |-|||    /| |  | |   / /  
    \____/\_/ \|\_/ \|\_/\_\\_/  \_/  /_/   

    Charity Shared Contract
    by Samuel Cardillo (@cardillosamuel)
*/

pragma solidity ^0.8.17;

// - Create possibility to make it SBT 
// - Make them migratable

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
contract Charity is DefaultOperatorFilterer, ERC1155, Ownable {    
    constructor() ERC1155("") {}

    mapping (uint => address) public collectionCreator; // Keep an idea of who created the collection
    mapping (uint => mapping (address => bool)) public existingCollections; // Allow different users to be controlling the collection
    mapping (uint => string) public tokenURIs; // Different token URIs per collection
    mapping (uint => address) public fundsReceiver; // Where to send the money
    mapping (uint => bool) public isSoulbound;
    uint256 public amountOfCollections = 1;

    modifier isAuthorizedEditor(uint collectionId) {
        require(collectionCreator[collectionId] == _msgSender() || existingCollections[collectionId][_msgSender()], "Unauthorized"); 
        _;
    }

    modifier isCreator(uint collectionId) {
        require(collectionCreator[collectionId] == _msgSender(), "Unauthorized");
        _;
    }
    

    // Mint function
    function charitableMint(uint256[] calldata amount, address[] calldata receiver, uint256 collectionId) public payable {
        for(uint256 i = 0; i < receiver.length; i++) {
            _mint(receiver[i], collectionId, amount[i], "");
        }

        payable(fundsReceiver[collectionId]).transfer(msg.value);
    }

    // Management functions
    function toggleEditor(uint256 collectionId, address editorAddress) public isCreator(collectionId) {
        existingCollections[collectionId][editorAddress] = !existingCollections[collectionId][editorAddress];
    }

    function editMetadata(uint256 collectionId, string calldata newURI) public isAuthorizedEditor(collectionId) {
        tokenURIs[collectionId] = newURI;
    }

    function changeFundsReceiver(uint256 collectionId, address newReceiver) public isAuthorizedEditor(collectionId) {
        fundsReceiver[collectionId] = newReceiver;
    }

    function uri(uint256 collectionId) public view virtual override returns (string memory) {
        return tokenURIs[collectionId];
    }

    function createCollection(bool isSbt) public {
        uint256 collectionId = amountOfCollections;
        address collectionOwner = _msgSender();

        collectionCreator[collectionId] = collectionOwner;
        fundsReceiver[collectionId] = collectionOwner;
        isSoulbound[collectionId] = isSbt;

        amountOfCollections++;
    }

    // OpenSea Royalties Support

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}