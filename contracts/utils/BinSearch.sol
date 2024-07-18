// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ArrayHelper} from "@solarity/solidity-lib/libs/arrays/ArrayHelper.sol";
import {TypeCaster} from "@solarity/solidity-lib/libs/utils/TypeCaster.sol";

library BinSearch {
    using ArrayHelper for *;
    using TypeCaster for *;

    function lowerBoundMem(
        address[] memory arr_,
        address element_
    ) internal pure returns (uint256) {
        return lowerBoundMem(arr_.asUint256Array(), uint256(uint160(element_)));
    }

    function lowerBoundMem(
        uint256[] memory array,
        uint256 element_
    ) internal pure returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array[mid_] >= element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    function search(address[] storage arr_, address element_) internal view returns (bool) {
        return search(_asUint256ArrayStor(arr_), uint256(uint160(element_)));
    }

    function search(uint256[] storage arr_, uint256 element_) internal view returns (bool) {
        uint256 index_ = arr_.lowerBound(element_);

        return index_ < arr_.length && arr_[index_] == element_;
    }

    function _asUint256ArrayStor(
        address[] storage from_
    ) private pure returns (uint256[] storage array_) {
        assembly {
            array_.slot := from_.slot
        }
    }
}
