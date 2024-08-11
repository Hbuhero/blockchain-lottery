// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstant} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstant {
    Raffle raffle;
    HelperConfig helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    uint256 entranceFee = 0.05 ether;
    uint256 interval = 30;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callBackGasLimit;

    event RaffleEntered(address indexed player);
    event RaffleWinner(address indexed addressOfWinner);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();

        interval = helperConfig.getActiveNetworkConfig().interval;
        vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        gasLane = helperConfig.getActiveNetworkConfig().gasLane;
        subscriptionId = helperConfig.getActiveNetworkConfig().subscriptionId;
        callBackGasLimit = helperConfig
            .getActiveNetworkConfig()
            .callBackGasLimit;

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitialization() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenYouDontPayEnough() public {
        hoax(PLAYER, STARTING_BALANCE);
        vm.expectRevert();
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function testRecordPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();

        assertEq(PLAYER, raffle.getPlayer(0));
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__Calculating.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp((block.timestamp + interval) + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rstate = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance += entranceFee;
        numPlayers = 1;

        // expecting reverts with parameters
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rstate
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestID // This is a Fuzz test. Make foundry try as many time as possible to break your code
    ) public raffleEntered skipFork {
        // Fulfill random words cant be called with a wrong id. Hence called after perform
        // upkeep since the vrf coordinator is in the perform upkeep which generate the id
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // since fulfill random words is only called by vrf coordinato node, this test will
        // fail in actual test nets since we are mocking the coordinator
        // soln: do
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestID,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksWinnerResetAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        // Arrrange
        // Get more players in the raffle
        uint256 startingIndex = 1;
        uint256 additionalEntrants = 5;
        uint256 starting_balance = 1 ether;
        address expectedWinner = address(1);

        for (
            uint i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            hoax(address(uint160(i)), starting_balance);
            raffle.enterRaffle{value: 0.01 ether}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        console.log("starting perform upkeep");

        // THis records the logs we emit in our function
        vm.recordLogs();
        // We do perform upkeep to request the random words. It is done automatically in real
        // nets. Inside it has a vrf coordinator which requests the random words
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        // THis one takes the request id and consumer address. By doing so it refers to the
        // fulfill function in our contract
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        console.log("Passed fulfill random words");
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);
        console.log("tested winner");
        // assert(recentWinner == PLAYER);

        assert(uint256(raffleState) == 0);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != ANVIL_CHAINID) {
            return;
        }
        _;
    }
}
