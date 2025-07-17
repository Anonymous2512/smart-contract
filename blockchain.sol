// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract BitsBlockchain {
    address payable public owner;
    mapping(address => mapping(uint256 => Item)) public itemsBySeller; // Mapping to store items added by each seller
    mapping(address => uint256[]) public sellerItems; // Mapping to store item IDs added by each seller
    mapping(address => uint256[]) public record;
    
    struct Item {
        uint256 price;
        uint256 itemType; // 1 for laptops, 2 for mobiles
    }

    event ItemAdded(address seller, uint256 itemId, uint256 itemType, uint256 price);
    event ItemPurchased(address buyer, address seller, uint256 itemId, uint256 quantity);
    event Withdrawal(address owner, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function addItem(uint256 itemId, uint256 itemType, uint256 price) public {
        itemsBySeller[msg.sender][itemId] = Item(price, itemType);
        sellerItems[msg.sender].push(itemId); // Update seller's item list
        emit ItemAdded(msg.sender, itemId, itemType, price);
    }

    function fetchItem(uint256 itemId) public view returns (uint256, uint256) {
        return (itemsBySeller[getItemSeller(itemId)][itemId].itemType, itemsBySeller[getItemSeller(itemId)][itemId].price);
    }

   function getItemSeller(uint256 itemId) internal view returns (address) {
    for (uint256 i = 0; i < sellerItems[msg.sender].length; i++) {
        if (sellerItems[msg.sender][i] == itemId) {
            return msg.sender;
        }
    }
    revert("Item not found or does not belong to sender");
   }


function purchaseItem(uint256 itemId, uint256 quantity) public payable {
    address seller = getItemSeller(itemId);
    uint256 price = itemsBySeller[seller][itemId].price;
    require(price > 0, "Item does not exist");
    require(quantity > 0, "Quantity must be greater than zero");
    uint256 totalPrice = price * quantity;
    require(msg.value >= totalPrice, "Insufficient payment");

    record[msg.sender][itemId] += quantity;
    emit ItemPurchased(msg.sender, seller, itemId, quantity);
    payable(seller).transfer(msg.value); // Send payment to seller
    // Refund excess payment
    if (msg.value > totalPrice) {
        payable(msg.sender).transfer(msg.value - totalPrice);
    }
}

    function purchaseRecord(address user, uint256 itemId) public view returns (uint256) {
        return record[user][itemId];
    }

    function priceFilter(uint256 minPrice, uint256 maxPrice) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](sellerItems[msg.sender].length);
        uint256 itemCount = 0;
        for (uint256 i = 0; i < sellerItems[msg.sender].length; i++) {
            uint256 itemId = sellerItems[msg.sender][i];
            uint256 price = itemsBySeller[msg.sender][itemId].price;
            if (price >= minPrice && price <= maxPrice) {
                result[itemCount] = itemId;
                itemCount++;
            }
        }
        uint256[] memory finalResult = new uint256[](itemCount);
        for (uint256 j = 0; j < itemCount; j++) {
            finalResult[j] = result[j];
        }
        return finalResult;
    }


function typeFilter(uint256 itemType) public view returns (uint256[] memory) {
    require(itemType == 1 || itemType == 2, "Invalid itemType. Only 1 or 2 allowed.");
    
    uint256[] memory result = new uint256[](sellerItems[msg.sender].length);
    uint256 itemCount = 0;
    for (uint256 i = 0; i < sellerItems[msg.sender].length; i++) {
        uint256 itemId = sellerItems[msg.sender][i];
        uint256 storedItemType = itemsBySeller[msg.sender][itemId].itemType;
        if (storedItemType == itemType) {
            result[itemCount] = itemId;
            itemCount++;
        }
    }
    uint256[] memory finalResult = new uint256[](itemCount);
    for (uint256 j = 0; j < itemCount; j++) {
        finalResult[j] = result[j];
    }
    return finalResult;
}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner).transfer(balance);
        emit Withdrawal(owner, balance);
    }

    receive() external payable {}
}


