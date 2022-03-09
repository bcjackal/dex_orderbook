pragma solidity ^0.8.0;

import "./wallet.sol";

contract Dex is Wallet {

    using SafeMath for uint256;

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderbook;

    function getOrderbook(bytes32 ticker, Side side) view public returns(Order[] memory) {
        return orderbook[ticker][uint(side)];
    }

    // market order
    /**
    * 1) createMarketOrder
    *    - buy => sell side orderbook, sell => buy side orderbook (done)
    *    - buy => check if hv enough eth, sell => check if hv enough token (done)
    *    - buy => token+ eth-, sell => token- eth+ (done)
    *        - limit orders placer need to modify eth/token too (done)
    *
    * 2) orderbook
    *    - when receiving a marketorder, pick the best rate first
    *    - able to submit even the orderbook is empty
    *    - loop through the books until the order is filled or the book is emptied
    *    - filled orders should be remove from orderbook
    */

    function createMarketOrder(Side _side, bytes32 _ticker, uint _amount) public {
        if (_side == Side.SELL) require(balances[msg.sender][_ticker] >= _amount, "not enough token to sell at market");

        uint getWhichBook = _side == Side.BUY ? 1 : 0; // buy order get sell orderbook , vice versa
        Order[] storage orders = orderbook[_ticker][getWhichBook]; // reference of orderbook (not copy)

        // sellbook : [$400 x 10 , $500 x 10, $600 x 30]
        // buy _amount = 20
        // buybook : [$300 x 10 , $200 x 10, $100 x 30]
        // sell _amount = 20

        uint totalFilled = 0;

        for (uint i = 0; i < orders.length && totalFilled < _amount; i++) {
            uint amountToBeFilled = _amount.sub(totalFilled); // amount need to be filled (original _amount - total filled amount)
            uint orderAmount = orders[i].amount.sub(orders[i].filled); // order in orderbook (order amount - filled amount)

            uint filled = amountToBeFilled >= orderAmount ? orderAmount : amountToBeFilled;
            totalFilled = totalFilled.add(filled);
            orders[i].filled = filled;
            uint orderCost = filled.mul(orders[i].price);

            if (_side == Side.BUY) {
                // checks
                require(balances[msg.sender]["ETH"] >= orderCost, "not enough eth to buy at market");
                // effects
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(orderCost);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(orderCost);

                balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(filled);
                balances[orders[i].trader][_ticker] = balances[orders[i].trader][_ticker].sub(filled);
                // interactions
                    // should hv no interactions with other contracts as the token/eth is originally deposited to this contract already
                    // we just modify the internal record to update the balances

            }
            else if (_side == Side.SELL) {
                // checks
                    // require(balances[msg.sender][_ticker] >= _amount, "not enough token to sell at market");
                    // put it at the top for saving gas
                // effects
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(orderCost);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(orderCost);

                balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(filled);
                balances[orders[i].trader][_ticker] = balances[orders[i].trader][_ticker].add(filled);
                // interactions
                    // should hv no interactions with other contracts as the token/eth is originally deposited to this contract already
                    // we just modify the internal record to update the balances
            }
        }

        //Remove 100% filled orders from the orderbook
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            //Remove the top element in the orders array by overwriting every element
            // with the next element in the order list
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }

    }


    function createMarketOrderx(Side side, bytes32 ticker, uint amount) public {
        
        if (side == Side.BUY) {
            Order[] storage orders = orderbook[ticker][1]; // reference of orderbook (not copy)
            // sell side : [10 x 100,  10 x 200, 30 x 300]
            // mkt size = 5

            for (uint i = 0; i < orders.length; i++) {
                if (amount >= orders[i].amount) { // eat whole order
                    // checks
                    require(balances[msg.sender]["ETH"] >= (orders[i].amount).mul(orders[i].price), "not enougth eth to buy at market");
                    // effects
                    balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub((orders[i].amount).mul(orders[i].price));
                    balances[orders[i].trader][bytes32("ETH")] = balances[orders[i].trader][bytes32("ETH")].add((orders[i].amount).mul(orders[i].price));

                    balances[msg.sender][ticker] = balances[msg.sender][ticker].add((orders[i].amount));
                    balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub((orders[i].amount));

                    // orders[i].isFilled = true;
                    amount = amount.sub(orders[i].amount);

                    // interactions
                        // should hv no interactions with other contracts as the token/eth is originally deposited to this contract already
                        // we just modify the internal record to update the balances
                }
                else if (amount != 0 && amount < orders[i].amount) {
                    // checks
                    require(balances[msg.sender]["ETH"] >= amount.mul(orders[i].price), "not enough eth to buy at market");
                    // effects
                    balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub(amount.mul(orders[i].price));
                    balances[orders[i].trader][bytes32("ETH")] = balances[orders[i].trader][bytes32("ETH")].add(amount.mul(orders[i].price));

                    balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
                    balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(amount);

                    uint tempOrderAmount = orders[i].amount;
                    orders[i].amount = orders[i].amount.sub(amount);
                    amount = amount.sub(tempOrderAmount);

                    // interactions
                        // should hv no interactions with other contracts as the token/eth is originally deposited to this contract already
                        // we just modify the internal record to update the balances
                }
            }

        
        }
        else if (side == Side.SELL) {
            Order[] storage orders = orderbook[ticker][0]; // reference of orderbook (not copy)
            // buy side : [10 x 300,  10 x 200, 30 x 100]
            // mkt size = 25

            for (uint i = 0; i < orders.length; i++) {
                if (amount >= orders[i].amount) { // eat whole order
                    // checks
                    require(balances[msg.sender][ticker] >= orders[i].amount, "not enough token to sell at market");
                    // effects
                    balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add((orders[i].amount).mul(orders[i].price));
                    balances[orders[i].trader][bytes32("ETH")] = balances[orders[i].trader][bytes32("ETH")].sub((orders[i].amount).mul(orders[i].price));

                    balances[msg.sender][ticker] = balances[msg.sender][ticker].sub((orders[i].amount));
                    balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add((orders[i].amount));

                    //orders[i].isFilled = true;
                    amount = amount.sub(orders[i].amount);
                    
                    // interactions
                        // should hv no interactions with other contracts as the token/eth is originally deposited to this contract already
                        // we just modify the internal record to update the balances
                }
                else if (amount != 0 && amount < orders[i].amount) {
                    // checks
                    require(balances[msg.sender][ticker] >= amount, "not enough token to sell at market");
                    // effects
                    balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(amount.mul(orders[i].price));
                    balances[orders[i].trader][bytes32("ETH")] = balances[orders[i].trader][bytes32("ETH")].sub(amount.mul(orders[i].price));

                    balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
                    balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(amount);

                    uint tempOrderAmount = orders[i].amount;
                    orders[i].amount = orders[i].amount.sub(amount);
                    amount = amount.sub(tempOrderAmount);

                    // interactions
                        // should hv no interactions with other contracts as the token/eth is originally deposited to this contract already
                        // we just modify the internal record to update the balances
                }
            }
        }
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public {
        if (side == Side.BUY) {
            require(balances[msg.sender]["ETH"] >= amount.mul(price));
        } 
        else if (side == Side.SELL) {
            require(balances[msg.sender][ticker] >= amount);
        }

        Order[] storage orders = orderbook[ticker][uint(side)]; // reference of orderbook (not copy)
       
        orders.push(
           Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)
        );

       // bubble sort 
        if (side == Side.BUY) {
            for (uint i = orders.length - 1; i > 0; i--) {
                if (orders[i].price > orders[i-1].price) {
                    Order memory tempOrder = orders[i-1];
                    orders[i-1] = orders[i];
                    orders[i] = tempOrder;
                }
            }
        } 
        else if (side == Side.SELL) {
            for (uint i = orders.length - 1; i > 0; i--) {
                if (orders[i].price < orders[i-1].price) {
                    Order memory tempOrder = orders[i-1];
                    orders[i-1] = orders[i];
                    orders[i] = tempOrder;
                }
            }

        }

        nextOrderId++;
    }
}