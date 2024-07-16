// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ArrayHelper} from "@solarity/solidity-lib/libs/arrays/ArrayHelper.sol";

library BinSearch {
    using ArrayHelper for *;

    function search(address[] storage arr_, address element_) internal view returns (bool) {
        return search(_asUint256Array(arr_), uint256(uint160(element_)));
    }

    function search(uint256[] storage arr_, uint256 element_) internal view returns (bool) {
        uint256 index_ = arr_.lowerBound(element_);

        return index_ < arr_.length && arr_[index_] == element_;
    }

    function _asUint256Array(
        address[] storage from_
    ) private pure returns (uint256[] storage array_) {
        assembly {
            array_.slot := from_.slot
        }
    }
}
