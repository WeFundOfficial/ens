//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "../registry/ENS.sol";
import "./ETHRegistrarController.sol";
import "./IETHRegistrarController.sol";
import "../resolvers/Resolver.sol";
import "./IBulkRenewal.sol";
import "./IPriceOracle.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract BulkRenewal is IBulkRenewal {
    bytes32 private constant TRX_NAMEHASH =
        0x52f0812dc843a11a98fe1f33f71f94232edb08fb1cdf8a3d04925482997fda1a;

    ENS public immutable ens;

    constructor(ENS _ens) {
        ens = _ens;
    }

    function getController() internal view returns (ETHRegistrarController) {
        Resolver r = Resolver(ens.resolver(TRX_NAMEHASH));
        return
            ETHRegistrarController(
                r.interfaceImplementer(
                    TRX_NAMEHASH,
                    type(IETHRegistrarController).interfaceId
                )
            );
    }

    function rentPrice(
        string[] calldata names,
        uint256 duration
    ) external view override returns (uint256 total) {
        ETHRegistrarController controller = getController();
        uint256 length = names.length;
        for (uint256 i = 0; i < length; ) {
            IPriceOracle.Price memory price = controller.rentPrice(
                names[i],
                duration
            );
            unchecked {
                ++i;
                total += (price.base + price.premium);
            }
        }
    }

    function renewAll(
        string[] calldata names,
        uint256 duration
    ) external payable override {
        ETHRegistrarController controller = getController();
        uint256 length = names.length;
        uint256 total;
        for (uint256 i = 0; i < length; ) {
            IPriceOracle.Price memory price = controller.rentPrice(
                names[i],
                duration
            );
            uint256 totalPrice = price.base + price.premium;
            controller.renew{value: totalPrice}(names[i], duration);
            unchecked {
                ++i;
                total += totalPrice;
            }
        }
        // Send any excess funds back
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) external pure returns (bool) {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IBulkRenewal).interfaceId;
    }
}
