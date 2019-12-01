These are some of the issues the HZ-USD will try to solve. The issues mainly come from exchanges having a certain mind-set regarding the tokens.

1. The 2% burn not to be taken off the transfer.

Some exchanges do not want the DEFL tokens because the number of expected tokens is never the number that is sent.
Solution is to simply send the right number of tokens and charge the 2% afterwards. Cancel if not enough tokens.

2. Make all code methods return a boolean

Some exchanges do not want to accept a transfer if a boolean is not returned.

3. Make a token printable, so they can be generated on a demand. Some exchanges require a large amount of tokens for liquidity.

- This generates multiple issues, and the token MUST have an owner.
- There must be only one token, and everything is to be regulated with maps within a contract.
- Owner addresses are to be restricted only to functions concerning the printing and burning.
- Only the owner can burn the tokens
- Only the owner can generate tokens
- There can be multiple owners of a contract
- Owners can add owners and remove owners (owner management)
- Owners can block anyone's transfer of the convertible tokens, and not the non-convertible
- Owners can burn anyone's convertible tokens, and not the non-convertible tokens
- Tokens that are printed cannot interact with the deposited amounts of USD
- There has to be a token reserve. For every 1USD within the token reserve, about 10K convertible tokens are printed.
- The reserve does not generate the non-convertible tokens.
- Only the owner can deposit to a reserve to get convertible tokens.
- Anyone can exchange the convertible tokens to USD within a reserve (while only the owner can generate convertible tokens).


MORE TO COME!
