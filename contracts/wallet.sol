pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable{

    using SafeMath for uint256;

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokenMapping;
    bytes32[] public tokenList;

    mapping(address => mapping(bytes32 => uint256)) public balances;

    modifier tokenExist(bytes32 _ticker) {
        require(tokenMapping[_ticker].tokenAddress != address(0), "token does not exist");
        _;
    }

    function addToken(bytes32 _ticker, address _tokenAddress) external onlyOwner {
        // checks
            // checked by modifier 'onlyOwner'
        // effects
            tokenMapping[_ticker] = Token(_ticker, _tokenAddress);
            tokenList.push(_ticker);
        // interactions
    }
    
    function deposit(bytes32 _ticker, uint256 _amount) external tokenExist(_ticker) {
        // checks
            // checked by modifier 'tokenExist'
        // effects
            balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(_amount);
        // interactions
            IERC20(tokenMapping[_ticker].tokenAddress).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(bytes32 _ticker, uint256 _amount) external tokenExist(_ticker) {
        // checks
            require(balances[msg.sender][_ticker] >= _amount, "Insufficient balance.");
        // effects
            balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(_amount);
        // interactions
            // we need to interact with other token address for the withdraw
            // we need 2 things to interact :  1) the token interface 2) the token address
            // if we are building a dex for erc20 token, we can use the openzepplin's IERC20 interface for it
            IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, _amount);

    }

    function depositEth() external payable {
        // checks
        // effects
            balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(msg.value);
        // interactions
    }

    function withdrawEth(uint amount) external {
        // checks
            require(balances[msg.sender][bytes32("ETH")] >= amount, "Insufficient balance.");
        // effects
            balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub(amount);
        // interactions
            msg.sender.call{value : amount}("");
    }


}