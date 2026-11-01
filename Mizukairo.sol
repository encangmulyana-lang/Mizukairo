// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Mizukairo — Japanese Mythology NFT on BNB Smart Chain
/// @notice ERC-721, max supply 1,111, flat public mint price 0.0002 BNB.
/// Rarity is a metadata trait, not enforced by the mint function.
contract Mizukairo is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant MINT_PRICE = 0.0002 ether;
    uint256 public constant MAX_MINT_PER_WALLET = 10; // DRAFT proposal, not in spec

    uint256 public totalMinted;
    bool public mintPaused;
    string private _baseTokenURI;
    mapping(address => uint256) public mintedByWallet;

    event Minted(address indexed minter, uint256 indexed tokenId, uint256 price);
    event BaseURISet(string baseURI);
    event MintPausedChanged(bool paused);

    constructor(string memory baseURI_) ERC721("Mizukairo", "MIZUKAIRO") Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
    }

    function currentPrice() public pure returns (uint256) {
        return MINT_PRICE;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(!mintPaused, "Mizukairo: mint paused");
        require(quantity > 0, "Mizukairo: quantity 0");
        require(mintedByWallet[msg.sender] + quantity <= MAX_MINT_PER_WALLET, "Mizukairo: wallet limit");
        require(totalMinted + quantity <= MAX_SUPPLY, "Mizukairo: sold out");
        require(msg.value == MINT_PRICE * quantity, "Mizukairo: wrong BNB amount");
        for (uint256 i = 0; i < quantity; i++) {
            totalMinted += 1;
            uint256 tokenId = totalMinted;
            mintedByWallet[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
            emit Minted(msg.sender, tokenId, MINT_PRICE);
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURISet(baseURI_);
    }

    function setMintPaused(bool paused_) external onlyOwner {
        mintPaused = paused_;
        emit MintPausedChanged(paused_);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Mizukairo: token does not exist");
        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0
            ? string(abi.encodePacked(baseURI_, tokenId.toString(), ".json"))
            : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Mizukairo: nothing to withdraw");
        (bool ok, ) = payable(owner()).call{value: balance}("");
        require(ok, "Mizukairo: withdraw failed");
    }
}
