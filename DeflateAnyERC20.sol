pragma solidity >= 0.5 .0 < 0.7 .0;

/*


 _    ____________________________
| |  |   ____   __  __   ______  /
| |__|  |__  | |__) | | |     / / 
|  __    __| |  _  /  | |    / /  
| |  |  |____| | \ \  | |   / /__ 
|_|  |_________|  \_\ |_|  /_____| The General Token Wrapper v1.0
     
A deflationary stable-coin, with a constantly increasing price.

This is a general source code that can be applied for deflating any ERC20 token.
In a code, we are calling our token "token" and the token which is deflated a "depoist".
The fields that have to be changed are marked with " //TODO: CHANGE THIS".
If you decide to increase the ratio adding more decimals, you will have to reduce decimals from 18 to a lower number.
Nobody is responsible for any code adjustments except the people who made the adjustments.


In order to make a deposit work, we must approve the amount within a contract/token that is deflated.
Withdrawing does not require any approval. Please approve only the exact amounts.


 Symbol        :  HZ //TODO: CHANGE THIS
 Name          :  Hertz Token //TODO: CHANGE THIS
 Total supply  :  21,000.0 (or 21 thousand tokens) //TODO: CHANGE THIS
 Decimals      :  18 //TODO: CHANGE THIS
 Transfer Fees :  2% deducted from each transfer (a burning fee).
 Exchange Fees :  no fees deducted while purchasing, 
                  2% fee while converting back to deposits
*/

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
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    // function burnTokens(uint tokens) public returns(bool success); // for testing purposes only !
    
    function depositFunds(uint deposit) public returns(bool);
    function withdrawFunds(uint tokens) public returns (bool);
    
    function sellAllTokens() public;
    function depositToTokens(uint depositAmount) public view returns(uint);
    function tokensToDeposit(uint tokensAmount) public view returns(uint);
    
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
// We are making address(0) the owner, which means, nobody.
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
    
    
    ERC20Interface private token = ERC20Interface(0xc4704D2e1d7f278AE561d11345047F5F3d4B03A2);  //TODO: CHANGE THIS
    

    using SafeMath
    for uint;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint private _DECIMALSCONSTANT;
    uint public _totalSupply;
    uint public _currentSupply;
    uint public decimalsDifference;
    uint public depositDecimals;
    bool constructorLocked = false;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint public tokensDeposited;

// ------------------------------------------------------------------------------
// The constructor function is called only once, and parameters are set.
// We are making sure that the token owner becomes address(0), that is, no owner.
// ------------------------------------------------------------------------------
    constructor() public onlyOwner{
        if (constructorLocked) revert();
        constructorLocked = true; // a bullet-proof mechanism

        symbol = "HZ"; //TODO: CHANGE THIS
        name = "Hertz"; //TODO: CHANGE THIS
        decimals = 18; //TODO: CHANGE THIS
        _DECIMALSCONSTANT = 10 ** uint(decimals);
        _totalSupply = (uint(21000)).mul(_DECIMALSCONSTANT); //TODO: CHANGE THIS
        _currentSupply = 0;
        
        //since other tokens can have 18 decimals or less, we must take into account the decimal difference to make it 1:1 ratio
        depositDecimals = 0; //TODO: CHANGE THIS
        decimalsDifference = decimals - depositDecimals; 

        //We will transfer the ownership only once, making sure there is no owner.
        emit OwnershipTransferred(msg.sender, address(0));
        owner = address(0);
    }

// ------------------------------------------------------------------------------
// Total supply
// ------------------------------------------------------------------------------
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }
    
    
// ------------------------------------------------------------------------------
// Current supply
// ------------------------------------------------------------------------------
    function currentSupply() public view returns(uint) {
        return _currentSupply;
    }
    

// ------------------------------------------------------------------------------
// Get the token balance for the account
// ------------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns(uint balance) {
        return balances[tokenOwner];
    }

// ------------------------------------------------------------------------
// Transfer the tokens from owner's account to a `to` account
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
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

// ------------------------------------------------------------------------
// Token owner can approve for `spender` to transferFrom(...) `tokens`
// from the token owner's account
// ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

// ------------------------------------------------------------------------
// Transfer `tokens` from the `from` account to the `to` account
//
// The calling account must already have sufficient tokens approved
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
// This is a function which allows us to burn any amount of tokens.
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
// This view function shows how many tokens will be obtained for your deposits.
// - Decimals are included in the result
// - There is no fee for purchasing tokens
// -------------------------------------------------------------------------
    function depositToTokens(uint depositAmount) public view returns(uint) {
        if(_currentSupply==0 && tokensDeposited==0 ) return depositAmount.mul((uint (10))**decimalsDifference); //initial step
        if(tokensDeposited==0 || _currentSupply==0 || depositAmount==0) return 0;
        uint ret = (depositAmount.mul(_currentSupply)).div(tokensDeposited);
        ret = ret.mul((uint (10))**decimalsDifference);
        return ret;
    }
    
// ----------------------------------------------------------------------------
// This view function shows how much of a deposit will be obtained for your tokens.
// - You must include decimals for an input.
// - There is 2% fee for converting to deposits
// ----------------------------------------------------------------------------
    function tokensToDeposit(uint tokensAmount) public view returns(uint){
        if(tokensAmount==0 || tokensDeposited==0 || _currentSupply==0) return 0;
        uint ret = (tokensDeposited.mul(tokensAmount)).div(_currentSupply);
        ret = ret.sub(ret.div(50)); //2% fee, it stays to be shared with everyone
        return ret;
    }

// ------------------------------------------------------------------------
// This is the function which allows us to purchase tokens from a contract
// The amount of deposited tokens must be approved by the contract beforehand
// - Nobody collects Tokens. Tokens stay with a contract
// - There is a no fee for purchasing Tokens
// ------------------------------------------------------------------------
    function depositFunds(uint deposit) public returns(bool) {
        require(deposit>0);
        
        //This must be approved with the original contract
        //The original contract MUST have balanceOf function !
        uint actualDepositAmount = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), deposit);
        actualDepositAmount = (token.balanceOf(address(this))).sub(actualDepositAmount);
        
        if(actualDepositAmount==0) revert();
        
        uint tokens = depositToTokens(actualDepositAmount);
        if(_currentSupply.add(tokens)>_totalSupply) revert();
        if(tokens==0) revert();

        //mint new tokens
        emit Transfer(address(0), msg.sender, tokens);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _currentSupply = _currentSupply.add(tokens);
        tokensDeposited = tokensDeposited.add(actualDepositAmount); //order matters

        return true;
    }
    
// ------------------------------------------------------------------------
// This is the function which allows us to exchange tokens back to deposits
// - Burns tokens, returns deposits.
// ------------------------------------------------------------------------ 
    function withdrawFunds(uint tokens) public returns (bool) { 
        require(tokens>0);
        uint getDeposit = tokensToDeposit(tokens);
        require(getDeposit>0);
        
        //burn tokens to get a deposit
        emit Transfer(msg.sender, address(0), tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _currentSupply = _currentSupply.sub(tokens);
        
        token.transfer(msg.sender, getDeposit);
        
        tokensDeposited = tokensDeposited.sub(getDeposit);
        return true;
    }
    
// ------------------------------------------------------------------------
// This is the function which allows us to exchange all tokens back to deposits
// - Burns all tokens, returns deposits.
// ------------------------------------------------------------------------ 
    function sellAllTokens() public {
        withdrawFunds(balances[msg.sender]);
    }   
}
