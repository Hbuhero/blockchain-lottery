// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstant {
    /*  VRF Mock Vlaues*/
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public ANVIL_CHAINID = 31337;

    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant ENTRANCE_FEE = 0.01 ether;
    uint256 public constant INTERVAL = 30;
}

contract HelperConfig is CodeConstant, Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callBackGasLimit;
        address linkToken;
        address account;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == SEPOLIA_CHAINID) {
            activeNetworkConfig = getSepoliaNetworkConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entranceFee: ENTRANCE_FEE,
                interval: INTERVAL,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 39111760803336008240658977602989322502428985741279203966506764176025014868205,
                callBackGasLimit: 500000,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0xCE3CEEB3AB15E50aB502c406330fE99b16216fDB
            });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        } else {
            // create Mocks and new NetworkConfig
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
                    MOCK_BASE_FEE,
                    MOCK_GAS_PRICE_LINK,
                    MOCK_WEI_PER_UINT_LINK
                );
            LinkToken linkToken = new LinkToken();
            vm.stopBroadcast();
            return
                NetworkConfig({
                    entranceFee: ENTRANCE_FEE,
                    interval: INTERVAL,
                    vrfCoordinator: address(vrfCoordinatorMock),
                    gasLane: 0,
                    subscriptionId: 0, // gonna fix this
                    callBackGasLimit: 500000,
                    linkToken: address(linkToken),
                    account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
                });
        }
    }

    function getActiveNetworkConfig()
        external
        view
        returns (NetworkConfig memory)
    {
        return activeNetworkConfig;
    }
}
