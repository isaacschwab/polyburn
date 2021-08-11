//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract IkeToken is ERC721Enumerable, Ownable {
    // Safemath or else things go wrong ...
    using SafeMath for uint256;

    // Struct definitions
    struct TokenInfo {
        uint256 _createdDate;
    }

    // Keep track of information .......
    mapping(uint256 => TokenInfo) private _tokenInfo;         // Mapping of each token to its details
    
    // Private members
    string public _baseTokenURI;                              // Base URI

    // Public members
    uint256 public _maxTokens;                                   // Max pill supply
    uint256 public _tokenPrice = 60000000000000000;             // 0.06 ETH
                            
    uint public _maxMint = 15;                         // Max pill quantity purchase per mint call
    bool public _canMint = false;                         // Is sale active ?
    string public _provenance = "";                            // Concatenation of hash data for all pills.

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxSupply
    ) ERC721(name, symbol) {
        _maxTokens = maxSupply;
        _baseTokenURI = baseURI;
    }

    // Withdraw any funds from supporter mints
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Owner can reserve tokens
    function reserveTokens(uint256 quantity) public onlyOwner {
        uint256 createdDate = block.timestamp;
        for(uint i = 0; i < quantity; i++) {
            uint mintIndex = totalSupply();
            if (mintIndex < _maxTokens) {
                console.log(msg.sender, " ", mintIndex);
                _safeMint(msg.sender, mintIndex);
                _tokenInfo[mintIndex] = TokenInfo (createdDate);
            }
        }
    }

    // Mint Token
    //  must mint at least one token
    //  minting must be enabled
    function mintSupporter(uint numberOfTokens) public payable  {
        require(numberOfTokens > 0, "Must mint at least 1 token");
        require(_canMint, "Minting is not currently active");
        require(totalSupply().add(numberOfTokens) <= _maxTokens, "Exceeds total supply of tokens");
        require(numberOfTokens <= _maxMint, "Maximum mint value exceeded");
        require(_tokenPrice.mul(numberOfTokens) <= msg.value, 'Payment sent is not sufficient.');

        // Perform the minting process
        uint256 createdDate = block.timestamp;
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < _maxTokens) {
                _safeMint(msg.sender, mintIndex);
                _tokenInfo[mintIndex] = TokenInfo (createdDate);
            }
        }
    }

    // toggleSale
    //  -   Toggles sale on/off
    function toggleSale() public onlyOwner {
        _canMint = !_canMint;
    }

    // setMaxQuantityPerMint
    //  -   Sets the max quantity of tokens that can be minted at once
    function setMaxQuantityPerMint (uint256 quantity) public onlyOwner {
        _maxMint = quantity;
    }

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        console.log(_baseTokenURI);
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Updates the base token URI for the metadata
     */
    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    // setProvenance
    //  -   Sets the provenance hash
    function setProvenance(string memory __provenance)
        external
        onlyOwner
    {
        _provenance = __provenance;
    }

    // getTokenInfo
    function getTokenInfo(uint256 tokenId) public view returns(TokenInfo memory info) {
        require(_exists(tokenId), "That token has not been minted yet.");
        return _tokenInfo[tokenId];
    }
}
