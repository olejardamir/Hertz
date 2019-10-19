



Note: No, this project is not associated with ButtCoin (0xBUTT) in any way, except that the lead developer (myself) is taking it as a separate solo project. In order to see it working without a flaw, usability must be tested before the main launch.



## TODO FIXES
- add a "sellAllTokens" function

If any issues are detected, they will be fixed and links updated on this page and announced to Telegram: https://t.me/joinchat/Ote9nhcPmwqf4Kmh3Fh6Uw

If you have any questions about the steps below, please ask on Telegram: https://t.me/joinchat/Ote9nhcPmwqf4Kmh3Fh6Uw


The purpose of this document is a tutorial to how to test the Hertz token, and also to provide the instructions on how to obtain and trade the token once it launches.

To inspect the source-code, go to:
https://ropsten.etherscan.io/address/0xF1060C7F14115f35C01569424b2549AFB4eC4c2D#code

Before you start, you will need Metamask installed in a browser:
https://metamask.io/

Also, you will need some testing Ethereum deposited to your account:
https://teth.bitaps.com/

To obtain the Ethereum, you must switch your Metamask to a Ropsten network.
Please make a new account just for the testing purposes in Metamask, so you don’t expose your accounts while testing.  For a detailed explanation, see:
https://blog.bankex.org/how-to-buy-ethereum-using-metamask-ccea0703daec


There are only a few functions that you may want to test. Go to:
https://ropsten.etherscan.io/address/0xF1060C7F14115f35C01569424b2549AFB4eC4c2D#writeContract

Select “Connect to Web3” and press “OK” if prompted.

Then, try testing any of these functions

1. purchaseTokens – You must enter the amount in Ethereum (decimals allowed) that you are willing to spend. The result will be in Wei. A good calculator is: http://eth-converter.com/

2. purchaseEth – Once you have enough tokens, you may want to convert them back to Ethereum. NOTE: there are 18 decimals and you must include the decimals (without a point or a comma).

3. transfer – Transfer some tokens to any account, to see how the burning works and to see how much Ethereum you will be getting after that. You must include 18 decimals, without a point or a comma.

4. burn – you may want to burn some of your tokens, to see how much Ethereum you will be getting after that. You must include 18 decimals, without a point or a comma.


Try to stress-test the system as much as possible. Imagine that you are a hacker who wants to break the code and get as much Ethereum from the contract as possible.  You may also want to check the numbers with the view functions with their queries:
https://ropsten.etherscan.io/address/0xF1060C7F14115f35C01569424b2549AFB4eC4c2D#readContract


Please report any findings here, on telegram or on twitter.

Telegram: https://t.me/joinchat/Ote9nhcPmwqf4Kmh3Fh6Uw

Twitter: https://twitter.com/0xbutt

 
