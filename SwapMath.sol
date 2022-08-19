function _swap(uint amount0Out, uint amount1Out, address to, bytes memory data, address protocol) internal lock {
    require(amount0Out > 0 || amount1Out > 0, "USDFIPair: INSUFFICIENT_OUTPUT_AMOUNT");
    require(amount0Out < reserve0 && amount1Out < reserve1, "USDFIPair: INSUFFICIENT_LIQUIDITY");
    uint balance0; // 100000000
    uint balance1; // 100000000

    uint _feeAmount = feeAmount;
    uint feeDenominator = FEE_DENOMINATOR;

    {// scope for _token{0,1}, avoids stack too deep errors
      address _token0 = token0;
      address _token1 = token1;
      require(to != _token0 && to != _token1, "USDFIPair: INVALID_TO"); // optimistically transfer tokens
      if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
      if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // try transfer 5000000 tokens out
      if (data.length > 0) IUniswapCallee(to).uniswapCall(msg.sender, amount0Out, amount1Out, data);
      balance0 = IERC20(_token0).balanceOf(address(this)); // 105000000
      balance1 = IERC20(_token1).balanceOf(address(this)); // 95000000
    }
    uint amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0; // amount0In = 5 
    uint amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, "USDFIPair: INSUFFICIENT_INPUT_AMOUNT"); // true 
    {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
      uint balance0Adjusted = balance0.mul(feeDenominator).sub(amount0In.mul(_feeAmount)); // (105000000*100000)-5*300 = 10499999998500
      uint balance1Adjusted = balance1.mul(feeDenominator).sub(amount1In.mul(_feeAmount));// 95000000*100000 = 9500000000000
      require(balance0Adjusted.mul(balance1Adjusted) >= uint(reserve0).mul(reserve1).mul(feeDenominator ** 2), "USDFIPair: K"); // 10499999998500*9500000000000 >= (100000000*100000000)*(100000**2)
    } // 99749999985750000000000000 >= 100000000000000000000000000 = false , use amount1Out = 4000000 instead which results in balance1= 96000000, that will work
    {// scope for protocol fee management
      uint protocolInputFeeAmount = protocol != address(0) ? protocolFeeShare.mul(_feeAmount) : 0; // 95000 * 300 = 28500000
      if (protocolInputFeeAmount > 0) { // 28500000
        if (amount0In > 0) {// amount0In = 5000000
          address _token0 = token0;
          _safeTransfer(_token0, protocol, amount0In.mul(protocolInputFeeAmount) / (feeDenominator ** 2)); // 5000000*28500000 / (100000**2) = 14250 
          balance0 = IERC20(_token0).balanceOf(address(this)); // 105000000 - 14250 = 104985750 -> 14250 is 0,00285, which is exactly 95% of 0.3%, therefore, the math is validated 
        }
        if (amount1In > 0) {
          address _token1 = token1;
          _safeTransfer(_token1, protocol, amount1In.mul(protocolInputFeeAmount) / (feeDenominator ** 2));
          balance1 = IERC20(_token1).balanceOf(address(this));
        }
      }
    }
    _update(balance0, balance1, reserve0, reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }
  
  
  
  
  
  // THIS TEST WAS PERFORMED WITH A BALANCE OF 100 TOKENS PER TOKEN AND 6 DECIMALS, AN INPUTAMOUNT OF 5 AND AN OUTPUT AMOUNT OF 5. TO LET THE SWAP SUCCEED THE OUTPUTAMOUNT SHOULD BE SMALLER
  THAN 5, OTHERWISE THE PAIR COULD GET DRAINED
