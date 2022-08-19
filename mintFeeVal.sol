 function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
    address feeTo = IUSDFIFactory(factory).feeTo();
    feeOn = feeTo != address(0);
    uint _kLast = kLast;
    // gas savings
    if (feeOn) {
      if (_kLast != 0) {
        uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1)); // sqrt(6573090271535348138980*21431412452141093504) = 375327335394626088780
        uint rootKLast = Math.sqrt(_kLast); // sqrt(140870309437577327973634373019671954202849) = 375326936733266358793 
        if (rootK > rootKLast) { // deltaK = 398661359729987 
          uint d = (FEE_DENOMINATOR / ownerFeeShare).sub(1); // (100000 / 95000) -1 = 0
          uint numerator = totalSupply.mul(rootK.sub(rootKLast)); //375304350988666350246*(398661359729987) = 149619342877722018051803927331026802
          uint denominator = rootK.mul(d).add(rootKLast); // 375327335394626088780*0 + 375326936733266358793 = 375326936733266358793
          uint liquidity = numerator / denominator; // 149619342877722018051803927331026802/375326936733266358793
          if (liquidity > 0) _mint(feeTo, liquidity); // 398637369808743
        } // how much liqudity was minted compared to the fee accumulation to the pair? 398637369808743/398661359729987 -> this results in a minting of 99% from deltaK
      }
    } else if (_kLast != 0) {
      kLast = 0;
    }
  }
  
  // This example used the on chain data at https://bscscan.com/address/0xe4c050c9589aafe94c9a3b34bdafcd26ab4f9e8d#readContract on timestamp 1660837800
