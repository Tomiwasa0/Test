
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    function mulDivUp(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a * b + c - 1) / c;
    }

    function mulDivDown(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a * b) / c;
    }
}

library Errors {
    error NOT_ENOUGH_CREDIT(uint256 creditAmountIn, uint256 maxCredit);
    error NOT_ENOUGH_CASH(uint256 cashAmountOut, uint256 fees);
}

contract Main {
   uint256 constant PERCENT = 1e18;
     uint256 constant YEAR= 31536000;

    struct FeeConfig {
        uint256 fragmentationFee;
    }

   FeeConfig public feeConfig;

    function getSwapFeePercent( uint256 tenor) internal view returns (uint256) {
        // Dummy implementation
        return Math.mulDivUp(5e15, tenor, YEAR); // Assume swap fee is proportional to tenor for testing purposes.
    }
    function ratePerTenor() public view returns (uint256) {
        // Dummy implementation
        return 5e16;}

    function getSwapFee(uint256 cash, uint256 tenor) internal view returns (uint256) {
        return Math.mulDivUp(cash, getSwapFeePercent( tenor), PERCENT);
    }
    function getCashAmountOut(
        uint256 creditAmountIn,
        uint256 maxCredit,
        uint256 ratePerTenor,
        uint256 tenor
    ) public  view returns (uint256 cashAmountOut, uint256 fees) {
         uint256 swapFeePercent = getSwapFeePercent( tenor);

        uint256 maxCashAmountOut = Math.mulDivDown(creditAmountIn, PERCENT - swapFeePercent, PERCENT + ratePerTenor);

        if (creditAmountIn == maxCredit) {
            fees = getSwapFee( maxCashAmountOut, tenor);

            if (fees > maxCashAmountOut) {
                revert Errors.NOT_ENOUGH_CASH(maxCashAmountOut, fees);
            }

            cashAmountOut = maxCashAmountOut;
            // - fees;
        } else if (creditAmountIn < maxCredit) {
            fees = getSwapFee( maxCashAmountOut, tenor) + feeConfig.fragmentationFee;

            if (fees > maxCashAmountOut) {
                revert Errors.NOT_ENOUGH_CASH(maxCashAmountOut, fees);
            }

            cashAmountOut = maxCashAmountOut - feeConfig.fragmentationFee;
             //- fees;
        } else {
            revert Errors.NOT_ENOUGH_CREDIT(creditAmountIn, maxCredit);
        }
    }
     function setFragmentationFee() external {
        feeConfig.fragmentationFee = 5e6;
    }
     function protocolgetCashAmountOut(
        uint256 creditAmountIn,
        uint256 maxCredit,
        uint256 ratePerTenor,
        uint256 tenor
    ) public view returns (uint256 cashAmountOut, uint256 fees) {
        uint256 maxCashAmountOut = Math.mulDivDown(creditAmountIn, PERCENT, PERCENT + ratePerTenor);

        if (creditAmountIn == maxCredit) {
            // no credit fractionalization

            fees = getSwapFee(maxCashAmountOut, tenor);

            if (fees > maxCashAmountOut) {
                revert Errors.NOT_ENOUGH_CASH(maxCashAmountOut, fees);
            }

            cashAmountOut = maxCashAmountOut - fees;
        } else if (creditAmountIn < maxCredit) {
            // credit fractionalization

            fees = getSwapFee( maxCashAmountOut, tenor) + feeConfig.fragmentationFee;

            if (fees > maxCashAmountOut) {
                revert Errors.NOT_ENOUGH_CASH(maxCashAmountOut, fees);
            }

            cashAmountOut = maxCashAmountOut - fees;
        } else {
            revert Errors.NOT_ENOUGH_CREDIT(creditAmountIn, maxCredit);
        }
    }
}
