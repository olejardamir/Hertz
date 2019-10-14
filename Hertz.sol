pragma solidity >=0.5.0 <0.7.0;
 
                                                                                                                 
// The purpose of this token is to create a deflationary token whose medium-moving-average price will always increase.
// Since it is an ERC20 token, the price will always depend on a price of an Ethereum. Otherwise, oracles must be used.
// Token name is Hertz since the market price is expected to oscillate with time, while constantly increasing in a value.
// Each time we mint a new 1.0 token(s), we are increasing the price by 1% of the current price in Wei.
// NOTE: 1000000000 Wei = 0.000000001 ETH, also 1000000000 Wei = 1 Gwei
//
// Symbol        :  HZ
// Name          :  Hertz Token 
// Total supply  :  Infinite
// Decimals      :  11
// Total Supply  :  Infinite, limit depends on how much people want to purchase
// Transfer Fees :  1% for the burning fee, plus additional gas price for an extra transfer (burning).
// Author        :  Damir Olejar
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }

}

library ExtendedMath {

    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns(uint c) {
        if (a > b) return b;
        return a;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20Interface {

    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    function purchaseFromContract(uint tokens) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;

}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}

 


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------

contract _HERTZ is ERC20Interface, Owned{

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint private _DECIMALSCONSTANT;
    uint private _WEICONSTANT = 10**uint(9);
    uint public _totalSupply;
    uint public _currentSupply;
    bool locked = false;
    uint public tokensMinted;
    uint public tokensBurned;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint public currentWeiPrice;
    uint public totalWeiBurned;

 
    // ------------------------------------------------------------------------
    // The constructor function is called only once, and parameters are set.
    // We are making sure that the token owner becomes address(0), that is, no owner.
    // ------------------------------------------------------------------------

    constructor() public onlyOwner {
        if (locked) revert();
        locked = true;

        symbol = "HZ";
        name = "Hertz";
        decimals = 11;
        _DECIMALSCONSTANT = 10**uint(decimals);
        _totalSupply = 0;
        _currentSupply = 0;
        tokensMinted = 0;
        tokensBurned = 0;
        
        uint weiTracker = gasleft();
        emit Transfer(address(0), msg.sender, 0);
        weiTracker = weiTracker.sub(gasleft());
        currentWeiPrice = weiTracker * _WEICONSTANT;
         
    }

    // ------------------------------------------------------------------------
    // This view function shows how much it will cost to buy tokens in Wei
    // ------------------------------------------------------------------------
    function tokensToPriceCalculator(uint tokens) public view returns(uint) {
        uint price = currentWeiPrice.div(100); //this is one percent
        price = (price.mul(tokens)).div(_DECIMALSCONSTANT);
        price = price.add(currentWeiPrice);
        return price;
    }
    
    
    // -------------------------------------------------------------------------
    // This view function shows how many tokens will be obtained for a given Wei
    // The price is off by + or - 5 Wei given the Solidity math limits
    // -------------------------------------------------------------------------
    function priceToTokensCalculator(uint fee) public view returns(uint) {  
        if(fee<currentWeiPrice) return 0;
        uint tokens = (fee.sub(currentWeiPrice).mul(_DECIMALSCONSTANT).mul(100)).div(currentWeiPrice);
        return tokens;
    }
    
    
    // ------------------------------------------------------------------------
    // The purpose of this function is to mint the tokens while burning ETH.
    // ------------------------------------------------------------------------
 
    
    function purchaseFromContract(uint tokens) public returns(bool){
 
        
        uint currentGas = gasleft()*_WEICONSTANT; //gas in Wei
        uint price = tokensToPriceCalculator(tokens);
        require(price>currentWeiPrice,"The price must increase"); 
        require(block.gaslimit.mul(_WEICONSTANT) >= price, "You don't have enough Ethereum");
        require(currentGas >= price, "You don't have enough Ethereum");
        
         
        emit Transfer(address(0), msg.sender, tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        tokensMinted = tokensMinted.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        _currentSupply = _totalSupply;
        currentWeiPrice = price; //increase the current wei price after minting
         
        currentGas = currentGas.sub(gasleft().mul(_WEICONSTANT));
        totalWeiBurned = totalWeiBurned.add(currentGas);
         
        if(price>currentGas){ 
            uint gweiToBurn = (currentWeiPrice.sub(currentGas.add(currentGas))).div(_WEICONSTANT); //current gas twice because we assume the cost of ETH transfer
            if(gweiToBurn>0){
                //TODO BURN ETH!
                totalWeiBurned = totalWeiBurned.add(currentWeiPrice.sub(currentGas.add(currentGas)));
            }
        }
 
         return true;
    }
    
     
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public view returns(uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns(bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0);
        require(address(to)!=address(0));
        
        uint burn = tokens.div(100); //1% burn
        uint send = tokens.sub(burn);
        _transfer(to, send);
        _transfer(address(0), burn);
        return true;
    }
    
    function _transfer(address to, uint tokens) internal returns(bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        if(address(to)!=address(0)){
            balances[to] = balances[to].add(tokens);
        }
        else if(address(to)==address(0)){
            _totalSupply = _totalSupply.sub(tokens);
            tokensBurned = tokensBurned.add(tokens);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------

    function transferFrom(address from, address to, uint tokens) public returns(bool) {
        require (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0);
        require(address(to)!=address(0));
        
        uint burn = tokens.div(100); //1% burn
        uint send = tokens.sub(burn);
        _transferFrom(from, to, send);
        _transferFrom(from, address(0), burn);
    }
    
    
    function _transferFrom(address from, address to, uint tokens) internal returns(bool) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        if(address(to)!=address(0)){
            balances[to] = balances[to].add(tokens);
        }
        else if(address(to)==address(0)){
            _totalSupply = _totalSupply.sub(tokens);
            tokensBurned = tokensBurned.add(tokens);
        }
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------

    // function () external payable {
    //     revert();
    // }
 
 

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}

