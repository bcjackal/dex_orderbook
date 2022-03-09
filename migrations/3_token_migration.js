const Link = artifacts.require("Link");
const Dex = artifacts.require("Dex");

module.exports = async function (deployer, network, accounts) {
  // added accounts
  await deployer.deploy(Link);

  // // we can write the initialization code here after deployment
  // let dex = await Dex.deployed();
  // let link = await Link.deployed();
  // console.log(`address : dex (${dex.address}) and link (${link.address})`);

  // // test actions
  // await link.approve(dex.address, 500); // approve the erc20 token for transfer
  // console.log(`allowance :`);
  // console.log(await link.allowance(accounts[0], dex.address));

  // await dex.addToken(web3.utils.fromUtf8("LINK"), link.address); // convert string to bytes32 by web3.utils
  // console.log(`token added: `);
  // console.log(await dex.tokenMapping(web3.utils.fromUtf8("LINK")));

  // await dex.deposit(web3.utils.fromUtf8("LINK"), 100);

  // // output of test
  // let balanceOfLink = await dex.balances(
  //   accounts[0], // need to include it in the deploy function
  //   web3.utils.fromUtf8("LINK")
  // );
  // console.log(balanceOfLink);
};
