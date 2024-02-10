// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin\contracts\token\ERC721\extensions\ERC721URIStorage.sol"; // to handle the ownership of the contract
import "@openzeppelin\contracts\utils\Counters.sol"; // to auto-increment the tokenID
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketPlace is ERC721URIStorage {
    using counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSolds;

    unit256 listingPrice = 0.0015 ether;

    address payable owner;

    mapping(uint256 => MarketItem) private  idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        // uint256 itemId;
        uint256 price;
        bool sold;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NFTMarketPlace: only owner can call this function");
        _;
    }

    event idMarketItemCreated(uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold);

    constructor () ERC721("NFT Metaverse Token", "MYNFT") {
        owner = payable(msg.sender);
    }

    function updateListingPrice(unit256 _listingPrice)public payable onlyOwner{
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (unit256){
        return listingPrice;
    }

    function createToken(string memory tokenURI, unit256 price) public payable returns (uint256){
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        createMarketItem(tokenId, price);
        return tokenId;
    }


    function createMarketItem(uint256 tokenId, uint256 price) public {
        require(price > 0, "NFTMarketPlace: price must be greater than 0");
        require(msg.value == listingPrice, "NFTMarketPlace: listing price must be equal to the listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    function reSellToken(uint256 tokenId, uint256 price) public payable{
        require(idMarketItem[tokenId].owner == msg.owner, "NFTMarketPlace: only owner can call this function");
        require(msg.value == listingPrice, "NFTMarketPlace: listing price must be equal to the listing price");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSolds.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    function createMarketSell(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;
        require(msg.value == price, "NFTMarketPlace: invalid price");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemsSolds.increment();
        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);

        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory){
        uint256 itemCount = _itemsSolds.current();
        uint256 unsoldItemCount = itemCount - _itemsSolds.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++){
            if (idMarketItem[i + 1].owner == address(this)){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFT() public view returns (MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        unit256 currentIndex = 0;

        // MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < itemCount; i++){
            if (idMarketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i + 1].owner == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        // MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++){
            if (idMarketItem[i + 1].seller == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i + 1].seller == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}