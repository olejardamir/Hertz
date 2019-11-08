var Web3 = require('web3');
var TruffleContract = require('truffle-contract');
 
App = {
    web3Provider: null,
    contracts: {},
    currentAccount:{},
    initWeb3 : async function (){
        if (process.env.MODE == 'development' || typeof window.web3 === 'undefined'){
            App.web3Provider = new Web3.providers.HttpProvider(process.env.LOCAL_NODE);
        }
        else{
             App.web3Provider = web3.currentProvider;
        }
        web3 = new Web3(App.web3Provider);
        return  await App.initContractHelloWorld(); 
    },
    initContractHelloWorld : async function (){
        await $.getJSON('HelloWorld.json',function(data){
            var HelloWorldArtifact = data;
            App.contracts.HelloWorld = TruffleContract(HelloWorldArtifact);
            App.contracts.HelloWorld.setProvider(App.web3Provider);        
        })
        return App.bindEvents();
    },
    bindEvents: function() { 
        $('#buttonMessage').click(App.loadMessage);
    },
    loadMessage : function (){
        App.contracts.HelloWorld.deployed().then(async function(instance){
            let message;
            if(App.currentAccount.length){
                message = await instance.getMessage.call({from:App.currentAccount});   
            }
            else{
                message = await instance.getMessage.call();  
            }
            App.showMessage(message);
        }).catch((err) =>{
            App.showError(err);
        })
    },
    showMessage: function (msg){
        $('#output').html(msg.toString());
        $('#errorHolder').hide();
        $('#output').show();
    },
    showError: function(err){
        $('#errorHolder').html(err.toString());
        $('#errorHolder').show();
        $('#output').hide();
    },
    init : async function (){
        await App.initWeb3();       
        App.loadMessage();          
    }
 
}  
 
$(function() {
    $(window).load(function() {
        $('#errorHolder').hide();
        $('#output').hide();
         
      App.init();
    });
  });
