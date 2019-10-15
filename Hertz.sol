pragma solidity >= 0.5 .0 < 0.7 .0;

/*

  -------                      -------  
 |███████|                   .|███████| 
 |███████|                   .|███████| 
 |███████|                   .|███████| 
 |███████|------             '|███████| 
 |████████████|--          .|-████████| 
 |██████████|--          .|-██████████| 
 |████████|--          .|-████████████| 
 |███████|            .|------|███████| 
 |███████|                   .|███████| 
 |███████|                   .|███████| 
 |███████|       HERTZ       .|███████| 
  -------                      ------- 

*/


// The purpose of this token is to create a deflationary token whose medium-moving-average price will always increase.
// Since it is an ERC20 token, the price will always depend on a price of Ethereum. Otherwise, oracles must be used.
// Token name is Hertz since the market price is expected to oscillate with time, while constantly increasing in a value.
// Each time we mint a new 1.0 token(s), we are increasing the price by 1% of the current price in Wei.
//
// Symbol        :  HZ
// Name          :  Hertz Token 
// Total supply  :  Infinite
// Decimals      :  11
// Total Supply  :  Infinite, limit depends on how much people want to invest
// Transfer Fees :  1% for the burning fee
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

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
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

    function purchaseTokens() external payable;

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
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------

contract _HERTZ is ERC20Interface, Owned {

    using SafeMath
    for uint;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint private _DECIMALSCONSTANT;
    uint public _totalSupply;
    uint public _currentSupply;
    bool constructorLocked = false;
    uint public tokensMinted;
    uint public tokensBurned;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint public weiPerToken;
    uint public totalWeiBurned;


    // ------------------------------------------------------------------------
    // The constructor function is called only once, and parameters are set.
    // We are making sure that the token owner becomes address(0), that is, no owner.
    // ------------------------------------------------------------------------

    constructor() public onlyOwner{
        if (constructorLocked) revert();
        constructorLocked = true;

        symbol = "HZ";
        name = "Hertz";
        decimals = 11;
        _DECIMALSCONSTANT = 10 ** uint(decimals);
        _totalSupply = 0;
        _currentSupply = _totalSupply;
        tokensMinted = 0;
        tokensBurned = 0;
        weiPerToken = 100000000000000; //This is our initial price in Wei
        
        emit OwnershipTransferred(msg.sender, address(0));
        owner = address(0);
        newOwner = address(0);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }
    
    
    // ------------------------------------------------------------------------
    // Current supply
    // ------------------------------------------------------------------------
    function currentSupply() public view returns(uint) {
        return _currentSupply;
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
    // - 0 value transfers are not allowed
    // - We cannot use this function for burning tokens
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns(bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0, "Zero transfer or not enough funds");
        require(address(to) != address(0), "No burning allowed");
        require(address(msg.sender) != address(0), "You can't mint this token, purchase it instead");

        uint burn = tokens.div(100); //1% burn
        uint send = tokens.sub(burn);
        _transfer(to, send);
        _transfer(address(0), burn);
        return true;
    }


    // -------------------------------------------------------------------------
    // The internal transfer function. We don't keep a balance of a burn address
    // -------------------------------------------------------------------------
    function _transfer(address to, uint tokens) internal returns(bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        if (address(to) != address(0)) {
            balances[to] = balances[to].add(tokens);
        } else if (address(to) == address(0)) {
            _totalSupply = _totalSupply.sub(tokens);
            _currentSupply = _totalSupply;
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
    // - 0 value transfers are not allowed
    // - This function cannot be used for burning tokens.
    // - This function cannot be used for minting tokens.
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns(bool) {
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0, "Zero transfer or not enough (allowed) funds");
        require(address(to) != address(0), "No burning allowed");
        require(address(from) != address(0), "You can't mint this token, purchase it instead");

        uint burn = tokens.div(100); //1% burn
        uint send = tokens.sub(burn);
        _transferFrom(from, to, send);
        _transferFrom(from, address(0), burn);
    }


    // -----------------------------------------------------------------------------
    // The internal transferFrom function. We don't keep a balance of a burn address
    // -----------------------------------------------------------------------------
    function _transferFrom(address from, address to, uint tokens) internal returns(bool) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        if (address(to) != address(0)) {
            balances[to] = balances[to].add(tokens);
        } else if (address(to) == address(0)) {
            _totalSupply = _totalSupply.sub(tokens);
            _currentSupply = _totalSupply;
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

    // ---------------------------------------------------------------------------------
    // This view function shows how the price will increase after the purchase of tokens
    // - The result is in Wei
    // ---------------------------------------------------------------------------------
    function showPriceIncrease(uint tokens) public view returns(uint) {
        uint wdiv = weiPerToken.div(100); //this is 1% of a price
        uint increase = tokens.mul(wdiv);
        increase = increase.div(_DECIMALSCONSTANT); //we are including decimals
        increase = weiPerToken.add(increase);
        return increase;
    }

    // -------------------------------------------------------------------------
    // This view function shows how many tokens will be obtained for your Wei.
    // This formula was derived from the showPriceIncrease function.
    // - Decimals are included in the result
    // -------------------------------------------------------------------------
    function weiToTokens(uint fee) public view returns(uint) {
        uint var_a = _DECIMALSCONSTANT.mul(weiPerToken).mul(fee); // DWF
        uint var_b = _DECIMALSCONSTANT.mul(_DECIMALSCONSTANT).mul(weiPerToken).mul(weiPerToken).mul(25); //25 D^2 W^2
        uint var_c = (var_b.add(var_a)).sqrt(); //sqrt(25 D^2 W^2 + D F W) 
        uint var_d = _DECIMALSCONSTANT.mul(5).mul(weiPerToken); //5 D W
        uint var_e = var_c.sub(var_d); //(sqrt(25 D^2 W^2 + D F W) - 5 D W)
        uint t = ((var_e.mul(10)).div(weiPerToken)).mul(_DECIMALSCONSTANT); //_DECIMALSCONSTANT included
        
        return t;
    }

    // ------------------------------------------------------------------------
    // This is the function which allows us to purchase tokens from a contract
    // - Nobody collects Ethereum, it is burned instead
    // ------------------------------------------------------------------------
    function purchaseTokens() external payable {
        uint tokens = weiToTokens(msg.value);
        require(tokens > 0, "You will get zero tokens with this purchase");

        uint increase = showPriceIncrease(tokens);
        require(increase > weiPerToken, "The purchase must increase the token price");
        weiPerToken = increase;

        emit Transfer(address(0), msg.sender, tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        tokensMinted = tokensMinted.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        _currentSupply = _totalSupply;

        totalWeiBurned = totalWeiBurned.add(msg.value);
        address(0).transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}
