var helloworld = artifacts.require('HelloWorld');

contract('HelloWorld', function(accounts) {
  let instance;
  before(async () => {
    instance = await helloworld.deployed();
  });
  it('Default message should be hello world',async () => {
    let message = await instance.getMessage.call({from: accounts[0]});           
    assert.equal(message, "Hello Cat","Incorrect message.");
  });
});
