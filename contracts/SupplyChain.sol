/*
    This exercise has been updated to use Solidity version 0.6
    Breaking changes from 0.5 to 0.6 can be found here: 
    https://solidity.readthedocs.io/en/v0.6.12/060-breaking-changes.html
*/

/*
    PROGRAMMER: Francis Mendoza
    EMAIL: fmendoz7@asu.edu
    ASSIGNMENT: Supply Chain Exercise
*/

pragma solidity >=0.6.0 <0.7.0;

contract SupplyChain {

  /* [X] set owner */
  address public owner;

  /* [X] Add a variable called skuCount to track THE MOST RECENT sku # */
  uint public skuCount;

  /* [X] Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  //Access an item through their sku number
  mapping (uint => Item) public items;

  /* [X] Add a line that creates an ENUM called State. This should have 4 states
    [X] ForSale
    [X] Sold
    [X] Shipped
    [X] Received
    (declaring them in this order is important for testing)
  */
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  //This merely initializes it
  //This enum lists the potential state of a product
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  //Per warnings from Solidity compiler, commented out to prevent shadowed declaration warning
  //State state;
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  /* [X] Create a struct named Item.
    [X] Here, add a name, sku, price, state, seller, and buyer
    We've left you to figure out what the appropriate types are,
    if you need help you can ask around :)
    Be sure to add "payable" to addresses that will be handling value transfer
  */
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  /* Create 4 events with the same name as each possible State (see above)
    [X] Prefix each event with "Log" for clarity, so the forSale event will be called "LogForSale"
    [X] Each event should accept ONE argument, the sku */

    //States can be found with the enum
    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);
/*------------------------------------------------------------------------------------------------------------------------------------------*/

/* [X] Create a modifer that checks if the msg.sender is the owner of the contract */
//Provided the function satisfies the conditions, modifier can MODIFY the behavior of the function
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  /* [X] For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. 
   Note that the uninitialized Item.State is 0, which is also the index of the ForSale value,
   so checking that Item.State == ForSale is not sufficient to check that an Item is for sale.
   Hint: What item properties will be non-zero when an Item has been added?
   
   PS: Uncomment the modifier but keep the name for testing purposes!
   */
  
  
  modifier forSale(uint sku) {
    //(!!!)
    require(items[sku].state == State.ForSale);
    require(items[sku].seller != address(0));
    _;
  }

  modifier sold(uint sku) {
    require(items[sku].state == State.Sold);
    _;
  }

  modifier shipped(uint sku) {
    require(items[sku].state == State.Shipped);
    _;
  }

  modifier received(uint sku) {
    require(items[sku].state == State.Received);
    _;
  }

/*------------------------------------------------------------------------------------------------------------------------------------------*/
  constructor() public {
    /* [X] Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
      owner = msg.sender;
      skuCount = 0;
  }
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  function addItem(string memory _name, uint _price) public returns(bool){
    emit LogForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  /* [X] Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 MODIFIERS to check if:
      - [X] The item is for sale,
      - [X] If the buyer paid enough
      - [X] Check the value after the function is called to make sure the buyer is refunded any excess ether sent. 
    Remember to call the event associated with this function!*/

  function buyItem(uint sku) public payable 
  forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
    //Wire money to seller, initialize buyer, change state of item to SOLD
    items[sku].seller.transfer(items[sku].price);
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;

    //EMIT: State Change that item was successfully sold
    emit LogSold(sku);
  }
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  /* [X] Add 2 modifiers to check if the item is:
    - [X] Sold already
    - [X] The person calling this function is the seller. 
  Change the state of the item to shipped. 
  Remember to call the event associated with this function!*/
  function shipItem(uint sku)
    public sold(sku) verifyCaller(items[sku].seller) {
      items[sku].state = State.Shipped;

      //EMIT: State changed for item to be shipped
      emit LogShipped(sku);
    }
/*------------------------------------------------------------------------------------------------------------------------------------------*/

  /* [X] Add 2 modifiers to check if the item is:
    - [X] Shipped already
    - [X] The person calling this function is the buyer
  Change the state of the item to received. 
  Remember to call the event associated with this function!*/
  function receiveItem(uint sku)
    public shipped(sku) verifyCaller(items[sku].buyer) {
      items[sku].state = State.Received;
      
      //EMIT: State changed for item as received
      emit LogReceived(sku);
    }

/*------------------------------------------------------------------------------------------------------------------------------------------*/

  /* We have these functions completed so we can run tests, just ignore it :) */
  //Uncomment to run tests successfully
  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
