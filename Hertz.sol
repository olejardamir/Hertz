pragma solidity >= 0.5 .0 < 0.7 .0;

/*
HZHZHZHZHZHZHZHZHZy..yHZHZHZHZHZHZHZHZHZ
HZHZHZHZHZHZHZHZm:    :mHZHZHZHZHZHZHZHZ
HZHZHZHZHZHZHZNo`      `sHZHZHZHZHZHZHZN
HZHZHZHZHZHZNd-          -dHZHZHZHZHZHZN
HZHZHZHZHZHZ+              +HZHZHZHZHZHZ
HZHZHZHZHZNdhyyyyyyyo-      .yHZHZHZHZHZ
HZHZHZHZHZHZHZHZHZHZHZs`      :mHZHZHZHZ
HZHZHZHZHZHZHZHZHZHZHZNm/      `sHZHZHZN
HZHZHZHZHZHZHZHZHZHZHZHZNh.      -dHZHZN
HZHZdddddmmmHZHZHZHZHZHZHZNo       +HZHZ
HZy`        .sHZHZHZm+++++++.       .yHZ
m:            -dHZHZNy.               :m
`               +HZHZHZ+               `
m:               .hHZHZNd-            :m
HZy`       .+++++++HZHZHZNs.        `yHZ
HZHZ+       +HZHZHZHZHZHZHZNmmmmddddHZHZ
HZHZNd-      .hHZHZHZHZHZHZHZHZHZHZHZHZN
HZHZHZNs`      /mHZHZHZHZHZHZHZHZHZHZHZN
HZHZHZHZm:      `sHZHZHZHZHZHZHZHZHZHZHZ
HZHZHZHZHZy.      -oyyyyyyyydHZHZHZHZHZN
HZHZHZHZHZHZ+              +HZHZHZHZHZHZ
HZHZHZHZHZHZNd-          -dHZHZHZHZHZHZN
HZHZHZHZHZHZHZNs`      `sHZHZHZHZHZHZHZN
HZHZHZHZHZHZHZHZm:    :mHZHZHZHZHZHZHZHZ
HZHZHZHZHZHZHZHZHZy..yHZHZHZHZHZHZHZHZHZ

     _    ____________________________
    | |  |   ____   __  __   ______  /
    | |__|  |__  | |__) | | |     / / 
    |  __    __| |  _  /  | |    / /  
    | |  |  |____| | \ \  | |   / /__ 
    |_|  |_________|  \_\ |_|  /_____| V1.0
     
A stable-coin, with a constantly increasing price.
*/
// Symbol        :  HZ
// Name          :  Hertz Token 
// Total supply  :  21,000.0 (or 21 thousand tokens)
// Decimals      :  18
// Total Supply  :  Infinite, limit depends on how much people want to invest
// Transfer Fees :  2% deducted from a transfer (a burning fee).
// Exchange Fees :  2% of tokens deducted per exchange.
// Author        :  Damir Olejar
//
// -----------------------------------------------------------------------------------------------------------------------------------------

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
// ERC Token Standard
// ----------------------------------------------------------------------------

contract ERC20Interface {

    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    // function burnTokens(uint tokens) public returns(bool success); // for testing purposes only !
    function purchaseTokens() external payable;
    function purchaseEth(uint tokens) external ;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// Owned contract, it is necessary to make 100% sure that there is no contract owner.
// We are making address(0) the owner, which means, nobody is an owner.
// ----------------------------------------------------------------------------

contract Owned {
    address public owner;

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
// ERC20 Token
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
    uint public weiDeposited;


// ------------------------------------------------------------------------------
// The constructor function is called only once, and parameters are set.
// We are making sure that the token owner becomes address(0), that is, no owner.
// ------------------------------------------------------------------------------

    constructor() public onlyOwner{
        if (constructorLocked) revert();
        constructorLocked = true; // a bullet-proof mechanism

        symbol = "HZ";
        name = "Hertz";
        decimals = 18;
        _DECIMALSCONSTANT = 10 ** uint(decimals);
        _totalSupply = (uint(21000)).mul(_DECIMALSCONSTANT);
        _currentSupply = 0;
        tokensMinted = 0;
        tokensBurned = 0;
        
        //We will transfer the ownership only once, making sure there is no owner.
        emit OwnershipTransferred(msg.sender, address(0));
        owner = address(0);
    }

// -----------------------------------------------------------------------------
// Total supply, since total amount is infinite, it is always the current supply
// -----------------------------------------------------------------------------
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }
    
    
// -------------------------------------------------------------------------------
// Current supply, since total amount is infinite, it is always the current supply
// -------------------------------------------------------------------------------
    function currentSupply() public view returns(uint) {
        return _currentSupply;
    }
    

// ------------------------------------------------------------------------
// Get the token balance for account the function executor
// ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns(uint balance) {
        return balances[tokenOwner];
    }

// ------------------------------------------------------------------------
// Transfer the balance from token owner's account to `to` account
// - Owner's account must have sufficient balance to transfer
// - 0 value transfers are not allowed
// - We cannot use this function to burn tokens
// ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns(bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0, "Zero transfer or not enough funds");
        require(address(to) != address(0), "No burning allowed");
        require(address(msg.sender) != address(0), "You can't mint this token, purchase it instead");

        uint burn = tokens.div(50); //2% burn
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
            _currentSupply = _currentSupply.sub(tokens);
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

        uint burn = tokens.div(50); //2% burn
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
            _currentSupply = _currentSupply.sub(tokens);
            tokensBurned = tokensBurned.add(tokens);
        }
        emit Transfer(from, to, tokens);
        return true;
    }

// ----------------------------------------------------------------------------------------------------
// Returns the amount of tokens approved by the owner that can be transferred to the spender's account
// ----------------------------------------------------------------------------------------------------
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
// This is the function which allows us to burn any amount of tokens.
// This is commented out and to be used for the testing purposes only.
// Otherwise, the contract could be abused in multiple ways.
// ------------------------------------------------------------------------     
    // function burnTokens(uint tokens) public returns(bool success) {
    //     balances[msg.sender] = balances[msg.sender].sub(tokens);
    //     _currentSupply = _currentSupply.sub(tokens);
    //     tokensBurned = tokensBurned.add(tokens);
    //     emit Transfer(msg.sender, address(0), tokens);
    //     return true;
    // }

// -------------------------------------------------------------------------
// This view function shows how many tokens will be obtained for your Wei.
// - Decimals are included in the result
// - There is no fee for purchasing tokens
// -------------------------------------------------------------------------
    function weiToTokens(uint weiPurchase) public view returns(uint) {
        if(_currentSupply==0 && weiDeposited==0 ) return weiPurchase; //initial step
        
        if(weiDeposited==0) return 0;
        if(_currentSupply==0) return 0;
        if(weiPurchase==0) return 0;
        
        uint ret = (weiPurchase.mul(_currentSupply)).div(weiDeposited);
        ret = ret.sub(ret.div(50)); //2% fee
        return ret;
    }
    
// ----------------------------------------------------------------------------
// This view function shows how much Wei will be obtained for your tokens.
// - You must include decimals for an input.
// - There is no fee for converting to Ethereum
// ----------------------------------------------------------------------------
    function tokensToWei(uint tokens) public view returns(uint){
        if(tokens==0) return 0;
        if(weiDeposited==0) return 0;
        if(_currentSupply==0) return 0;
        uint ret = (weiDeposited.mul(tokens)).div(_currentSupply);
        return ret;
    }

// ------------------------------------------------------------------------
// This is the function which allows us to purchase tokens from a contract
// - Nobody collects Ethereum, it stays in a contract
// - There is a 2% fee for purchasing Tokens
// ------------------------------------------------------------------------
    function purchaseTokens() external payable {
        
        uint tokens = weiToTokens(msg.value);
        require(_currentSupply.add(tokens)<=_totalSupply,"We have reached our contract limit");

        //mint new tokens
        emit Transfer(address(0), msg.sender, tokens);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        tokensMinted = tokensMinted.add(tokens);
        _currentSupply = _currentSupply.add(tokens);

        
        weiDeposited = weiDeposited.add(msg.value);
    }
    
// ------------------------------------------------------------------------
// This is the function which allows us to exchange tokens back to Ethereum
// - Burns deposited tokens, returns Ethereum.
// ------------------------------------------------------------------------ 
    function purchaseEth(uint tokens) external {
        uint getWei = tokensToWei(tokens);
        
        //burn tokens to get wei
        emit Transfer(msg.sender, address(0), tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _currentSupply = _currentSupply.sub(tokens);

        address(msg.sender).transfer(getWei);
        weiDeposited = weiDeposited.sub(getWei);
    }
}

// Legal Disclaimer: Author is not responsible for anyone using of this token. 
// Furthermore, author is not obligated to any activities that may be (or are) associated with this token.
// This token has no owner, and therefore, use it strictly at your own discretion.
// Author's name has been provided as a gesture of a good will, in hope that this disclaimer will remain only as a note.
// Written on Friday, October 18th 2019. - Toronto / Ontario, Canada.
