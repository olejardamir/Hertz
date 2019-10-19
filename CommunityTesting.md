The purpose of this document is a tutorial to how to test the Hertz token, and also to provide the instructions on how to obtain and trade the token once it launches.

To inspect the source-code, go to:
https://ropsten.etherscan.io/address/0x723b09eba9267d0e4415659ade75e6436384f693#code

Before you start, you will need Metamask installed in a browser:
https://metamask.io/

Also, you will need some testing Ethereum deposited to your account:
https://teth.bitaps.com/

To obtain the Ethereum, you must switch your Metamask to a Ropsten network.
Please make a new account just for the testing purposes in Metamask, so you don’t expose your accounts while testing.  For a detailed explanation, see:
https://blog.bankex.org/how-to-buy-ethereum-using-metamask-ccea0703daec


There are only a few functions that you may want to test. Go to:
https://ropsten.etherscan.io/address/0x723b09eba9267d0e4415659ade75e6436384f693#writeContract

Select “Connect to Web3” and press “OK” if prompted.

Then, try testing any of these functions

1. purchaseTokens – You must enter the amount in Ethereum (decimals allowed) that you are willing to spend.

2. purchaseEth – Once you have enough tokens, you may want to convert them back to Ethereum.

3. transfer – Transfer some tokens to any account, to see how the burning works and to see how much Ethereum you will be getting after that.

4. burn – you may want to burn some of your tokens, to see how much Ethereum you will be getting after that.


Try to stress-test the system as much as possible. Imagine that you are a hacker who wants to break the code and get as much Ethereum from the contract as possible.  You may also want to check the numbers with the view functions with their queries:
https://ropsten.etherscan.io/address/0x723b09eba9267d0e4415659ade75e6436384f693#readContract


Please report any findings here, on telegram or on twitter.
