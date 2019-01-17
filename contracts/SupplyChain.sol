pragma solidity ^0.5.0;

contract SupplyChain {

  /* set owner */
  address owner;

  /* Add a variable called skuCount to track the most recent sku # */
	uint public skuCount;

  /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
	mapping ( uint => Item) public items;

  /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
    (declaring them in this order is important for testing)
  */
	enum State {
		ForSale,
		Sold,
		Shipped,
		Received
	}

  /* struct named Item.
    Here, a name, sku, price, state, seller, and buyer
  */
	struct Item {
		string name;
		uint sku;
		uint price;
		State state;
		address payable seller;
		address payable buyer;
		
	}
   

  /* 4 events with the same name as each possible State (see above)
    Each event accept one argument, the sku*/
	event ForSale ( uint sku);
	event Sold ( uint sku);
	event Shipped ( uint sku);
	event Received ( uint sku);

/* modifer that checks if the msg.sender is the owner of the contract */

  modifier verifyCaller (address _address) { require (msg.sender == _address); _;}

  modifier paidEnough(uint _price) { require(msg.value >= _price); _;}
  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale ( uint sku ) { require (items[sku].state == State.ForSale); _;}
  modifier sold (uint sku ) { require (items[sku].state == State.Sold); _;}
  modifier shipped (uint sku) { require (items[sku].state == State.Shipped); _;}
  modifier received (uint sku) { require (items[sku].state == State.Received); _;}


  constructor() public {
    /* owner as the person who instantiated the contract
       and set skuCount to 0. */
	owner = msg.sender;
	skuCount =0 ;
  }

  function addItem(string memory _name, uint _price) public returns(bool){
    emit ForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  /* keyword so the function can be paid. This function  transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. this function  use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. call the event associated with this function!*/

  function buyItem(uint sku) forSale (sku) paidEnough(items[sku].price) checkValue(sku)
    public payable
  {
	items[sku].seller.transfer(items[sku].price);
	items[sku].buyer = msg.sender;
	items[sku].state = State.Sold;
	emit Sold(sku);
  }

  /* 2 modifiers to check if the item is sold already, and  person calling this function
  is the seller. Change the state of the item to shipped. call the event associated with this function!*/
  function shipItem(uint sku) sold(sku) verifyCaller(items[sku].seller)
    public
  {
	items[sku].state = State.Shipped;
	emit Shipped(sku);
  }

  /* 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. call the event associated with this function!*/
  function receiveItem(uint sku) shipped(sku) verifyCaller(items[sku].buyer)
    public
  {
	items[sku].state = State.Received;	
	emit Received(sku);
}

  function fetchItem(uint _sku) public view returns (string memory name, uint  sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
