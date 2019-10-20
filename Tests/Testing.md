https://ropsten.etherscan.io/address/0xedfb73f3e5cb853c415dd2cb59206a7e03d4ada3#code

1. Code deployable, views show proper numbers...
2. Test for zero purchases, purchases with high amounts, low amounts purchases...
3. Before purchasing see the view result, purchase, compare with the view...
4. Purchase with another account, send all to a third account...
5. Redeem ETH with the first account, there should be more ETH (decimals at least)...
6. Redeem ETH with the third account, there should not be less ETH....

Inspect each transaction data for validity

1. OK
2. OK
3. Initial purchase didn't apply the 2% fee, corrected!
-Problem: when taking a 2% fee from an initial purchase, the next purchase becomes more expensive. This can suggest a ponzi scheme.
Therefore, we must reduce from ETH instead.

3. OK
4. OK
5. OK
6. OK