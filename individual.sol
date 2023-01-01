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

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

// To do : 
// - Create possibility to make it SBT 
// - Create possibility to choose grades of token (achieved by msg.value >= a certain amount)
// - Make them migratable

contract CharityStandalone is DefaultOperatorFilterer, ERC1155, Ownable, ERC1155Burnable {    
    constructor() ERC1155("") {}

    mapping (address => bool) public authorizedEditors; // Keep an idea of who created the collection
    mapping (uint => string) public tokenURIs; // Different token URIs per collection
    address public fundsReceiver; // Where to send the money

    modifier isAuthorizedEditor() {
        require(owner() == msg.sender || authorizedEditors[msg.sender], "Unauthorized"); 
        _;
    }
    

    // Mint function
    function charitableMint(uint256[] calldata amount, address[] calldata receiver, uint256 tokenId) public payable {
        address fundsReceiverAddress = (fundsReceiver != 0x0000000000000000000000000000000000000000) ? fundsReceiver : owner();


        for(uint256 i = 0; i < receiver.length; i++) {
            _mint(receiver[i], tokenId, amount[i], "");
        }

        payable(fundsReceiverAddress).transfer(msg.value);
    }

    // Management functions
    function toggleEditor(address editorAddress) public onlyOwner() {
        authorizedEditors[editorAddress] = !authorizedEditors[editorAddress];
    }

    function editMetadata(uint256 tokenId, string calldata newURI) public isAuthorizedEditor() {
        tokenURIs[tokenId] = newURI;
    }

    function changeFundsReceiver(address newReceiver) public isAuthorizedEditor() {
        fundsReceiver = newReceiver;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenURIs[tokenId];
    }

    // OpenSea Royalties Support

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}