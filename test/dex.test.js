const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require("truffle-assertions");

contract.skip("Dex", (accounts) => {
  // limit order
  it("should throw an error if ETH balance is too low when creating BUY limit order", async () => {
    let dex = await Dex.deployed();

    // reverts if hv not enough eth
    await truffleAssert.reverts(
      dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 10, 1)
    );

    // passes if hv enough eth
    await dex.depositEth({ value: 10 });
    await truffleAssert.passes(
      dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 10, 1)
    );
  });

  it("should thorw an error if token balance is not enough when creating SELL limit order", async () => {
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    // reverts if hv not enough link
    await truffleAssert.reverts(
      dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 10, 1)
    );
    // pass if hv enough link
    await link.approve(dex.address, 500);
    await dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {
      from: accounts[0],
    });
    await dex.deposit(web3.utils.fromUtf8("LINK"), 100);

    await truffleAssert.passes(
      dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 10, 1)
    );
  });

  it("should be ordering the BUY orderbook from highest to lowest", async () => {
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await link.approve(dex.address, 500);
    await dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {
      from: accounts[0],
    });

    await dex.depositEth({ value: 3000 });

    await dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 1, 300);
    await dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 1, 100);
    await dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 1, 200);

    let orderbook = await dex.getOrderbook(web3.utils.fromUtf8("LINK"), 0);

    assert(orderbook.length > 0);
    for (let i = 0; i < orderbook.length - 1; i++) {
      assert(
        orderbook[i].price > orderbook[i + 1].price,
        "not right order in buy book"
      );
    }
  });

  it("should be ordering the SELL orderbook from lowest to highest", async () => {
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await link.approve(dex.address, 500);
    await dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {
      from: accounts[0],
    });

    await dex.depositEth({ value: 3000 });

    await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1, 500);
    await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1, 400);
    await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1, 700);

    let orderbook = await dex.getOrderbook(web3.utils.fromUtf8("LINK"), 1);

    assert(orderbook.length > 0);

    for (let i = 0; i < orderbook.length - 1; i++) {
      assert(
        orderbook[i].price < orderbook[i + 1].price,
        "not right order in sell book"
      );
    }
  });
});
