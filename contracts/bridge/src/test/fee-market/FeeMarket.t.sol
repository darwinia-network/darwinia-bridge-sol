// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
import "../../fee-market/FeeMarket.sol";

contract FeeMarketTest is DSTest {
    uint256 constant internal COLLATERAL_PERORDER = 1 ether;
    uint32  constant internal ASSIGNED_RELAYERS_NUMBER = 3;
    uint32  constant internal SLASH_TIME = 1 days;
    uint32  constant internal RELAY_TIME = 1 days;

    address public vault = address(111);
    address public self;

    FeeMarket public market;
    Guy       public a;
    Guy       public b;
    Guy       public c;


    function setUp() public {
        market = new FeeMarket(
            vault,
            COLLATERAL_PERORDER,
            ASSIGNED_RELAYERS_NUMBER,
            SLASH_TIME,
            RELAY_TIME
        );
        self = address(this);
        a = new Guy(market);
        b = new Guy(market);
        c = new Guy(market);
    }

    function test_constructor_args() public {
        assertEq(market.owner(), self);
        assertEq(market.VAULT(), vault);
        assertEq(market.collateralPerorder(), COLLATERAL_PERORDER);
        assertEq(market.assignedRelayersNumber(), ASSIGNED_RELAYERS_NUMBER);
        assertEq(market.slashTime(), SLASH_TIME);
        assertEq(market.relayTime(), RELAY_TIME);
    }

    function test_set_owner() public {
        market.setOwner(vault);
        assertEq(market.owner(), vault);
    }

    function test_set_outbound() public {
        market.setOutbound(self, 1);
        assertEq(market.outbounds(self), 1);
    }

    function test_set_para_time() public {
        market.setParaTime(2 days, 3 days);
        assertEq(market.slashTime(), 2 days);
        assertEq(market.relayTime(), 3 days);
    }

    function test_set_para_relay() public {
        market.setParaRelay(5, 1 wei);
        assertEq(market.assignedRelayersNumber(), 5);
        assertEq(market.collateralPerorder(), 1 wei);
    }

    function test_initial_state() public {
        assert_eth_balance    (a, 0 ether);
        assert_market_balance (a, 0 ether);
        assert_eth_balance    (b, 0 ether);
        assert_market_balance (b, 0 ether);
        assert_eth_balance    (c, 0 ether);
        assert_market_balance (c, 0 ether);

        assert_market_supply  (0 ether);
    }

    function test_join() public {
        perform_join          (a, 3 ether);
        assert_market_balance (a, 3 ether);
        assert_market_balance (b, 0 ether);
        assert_eth_balance    (a, 0 ether);
        assert_market_supply  (3 ether);

        perform_join          (a, 4 ether);
        assert_market_balance (a, 7 ether);
        assert_market_balance (b, 0 ether);
        assert_eth_balance    (a, 0 ether);
        assert_market_supply  (7 ether);

        perform_join          (b, 5 ether);
        assert_market_balance (b, 5 ether);
        assert_market_balance (a, 7 ether);
        assert_market_supply  (12 ether);
    }

    function testFail_exit_1() public {
        perform_exit          (a, 1 wei);
    }

    function testFail_exit_2() public {
        perform_join          (a, 1 ether);
        perform_exit          (b, 1 wei);
    }

    function testFail_exit_3() public {
        perform_join          (a, 1 ether);
        perform_join          (b, 1 ether);
        perform_exit          (b, 1 ether);
        perform_exit          (b, 1 wei);
    }

    function test_exit() public {
        perform_join          (a, 7 ether);
        assert_market_balance (a, 7 ether);
        assert_eth_balance    (a, 0 ether);

        perform_exit          (a, 3 ether);
        assert_market_balance (a, 4 ether);
        assert_eth_balance    (a, 3 ether);

        perform_exit          (a, 4 ether);
        assert_market_balance (a, 0 ether);
        assert_eth_balance    (a, 7 ether);
    }

    function test_enroll() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1 ether);
        assert_market_balance    (a, 1 ether);
        assert_market_supply     (1 ether);

        perform_enroll           (b, address(a), 1 ether, 1 ether);
        assert_market_is_relayer (b);
        assert_market_fee_of     (b, 1 ether);
        assert_market_balance    (b, 1 ether);
        assert_market_supply     (2 ether);

        perform_enroll           (c, address(b), 1 ether, 1.1 ether);
        assert_market_is_relayer (c);
        assert_market_fee_of     (c, 1.1 ether);
        assert_market_balance    (c, 1 ether);
        assert_market_supply     (3 ether);
    }

    function testFail_enroll_1() public {
        perform_enroll           (a, address(1), 1 ether, 1.1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
    }

    function testFail_enroll_2() public {
        perform_enroll           (a, address(1), 0.9 ether, 1 ether);
    }

    function test_unenroll() public {
        perform_enroll           (a, address(1), 7 ether, 1 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1 ether);
        assert_market_balance    (a, 7 ether);
        assert_market_supply     (7 ether);
        assert_eth_balance       (a, 0 ether);

        perform_unenroll         (a, address(1));
        assert_market_is_not_relayer (a);
        assert_market_fee_of     (a, 0 ether);
        assert_market_balance    (a, 0 ether);
        assert_market_supply     (0 ether);
        assert_eth_balance       (a, 7 ether);
    }

    function test_add_relayer() public {
        perform_join             (a, 3 ether);
        perform_join             (b, 4 ether);
        perform_join             (c, 5 ether);

        perform_add_relayer      (a, address     ( 1), 1 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1 ether);

        perform_add_relayer      (b, address     ( a), 1 ether);
        assert_market_is_relayer (b);
        assert_market_fee_of     (b, 1 ether);
        perform_add_relayer      (c, address     ( b), 1.1 ether);
        assert_market_is_relayer (c);
        assert_market_fee_of     (c, 1.1 ether);
    }

    function test_remove_relayer() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        perform_remove_relayer   (a, address(1));
        assert_market_is_not_relayer (a);
        assert_market_fee_of     (a, 0 ether);
        perform_remove_relayer   (b, address(1));
        assert_market_is_not_relayer (b);
        assert_market_fee_of     (b, 0 ether);
        perform_remove_relayer   (c, address(1));
        assert_market_is_not_relayer (c);
        assert_market_fee_of     (c, 0 ether);
    }

    function test_move_relayer() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        perform_move_relayer     (a, address(1), address(c), 1.2 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1.2 ether);
    }

    function test_market_status() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        address[] memory top = market.getTopRelayers();
        assertEq(top[0], address(a));
        assertEq(top[1], address(b));
        assertEq(top[2], address(c));

        (uint index, address[] memory relayers, uint[] memory fees, uint[] memory balances) = market.getOrderBook(3, true);
        assertEq(index, 3);
        assertEq(relayers[0], address(a));
        assertEq(relayers[1], address(b));
        assertEq(relayers[2], address(c));
        assertEq(fees[0], 1 ether);
        assertEq(fees[1], 1 ether);
        assertEq(fees[2], 1.1 ether);
        assertEq(balances[0], 1 ether);
        assertEq(balances[1], 1 ether);
        assertEq(balances[2], 1 ether);
    }

    function test_assign() public {
        init();
        uint key = 1;
        perform_assign(key, 1.1 ether);
        (uint index, address[] memory relayers, uint[] memory fees, uint[] memory balances) = market.getOrderBook(1, false);
        assertEq(index, 0);
        assertEq(relayers[0], address(0));
        assertEq(fees[0], 0 ether);
        assertEq(balances[0], 0 ether);

        assert_market_locked(a, 1 ether);
        assert_market_locked(b, 1 ether);
        assert_market_locked(c, 1 ether);

        Guy[] memory guys = new Guy[](3);
        guys[0] = a;
        guys[1] = b;
        guys[2] = c;
        assert_market_order(guys, key);
    }

    //------------------------------------------------------------------
    // Helper functions
    //------------------------------------------------------------------

    function init() public {
        market.setOutbound(self, 1);
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);
    }

    function assert_eth_balance(Guy guy, uint balance) public {
        assertEq(address(guy).balance, balance);
    }

    function assert_market_balance(Guy guy, uint balance) public {
        assertEq(market.balanceOf(address(guy)), balance);
    }

    function assert_market_locked(Guy guy, uint locked) public {
        assertEq(market.lockedOf(address(guy)), locked);
    }

    function assert_market_order(Guy[] memory guys, uint key) public {
        (uint32 assignedTime, uint32 assignedRelayersNumber, uint collateral) = market.orderOf(key);
        assertEq(assignedTime, block.timestamp);
        assertEq(assignedRelayersNumber, ASSIGNED_RELAYERS_NUMBER);
        assertEq(collateral, COLLATERAL_PERORDER);

        assertEq(guys.length, assignedRelayersNumber);
        for(uint slot = 0; slot < assignedRelayersNumber; slot++) {
            (address assignedRelayer, uint fee) = market.assignedRelayers(key, slot);
            assertEq(assignedRelayer, address(guys[slot]));
            assertEq(fee, market.feeOf(assignedRelayer));
        }
    }

    function assert_market_supply(uint supply) public {
        assertEq(market.totalSupply(), supply);
    }

    function assert_market_is_relayer(Guy guy) public {
        assertTrue(market.isRelayer(address(guy)));
    }

    function assert_market_is_not_relayer(Guy guy) public {
        assertTrue(!market.isRelayer(address(guy)));
    }

    function assert_market_fee_of(Guy guy, uint fee) public {
        assertEq(market.feeOf(address(guy)), fee);
    }

    function perform_join(Guy guy, uint wad) public {
        guy.join{value: wad}();
    }

    function perform_exit(Guy guy, uint wad) public {
        guy.exit(wad);
    }

    function perform_enroll(Guy guy, address prev, uint wad, uint fee) public {
        guy.enroll{value: wad}(prev, fee);
    }

    function perform_unenroll(Guy guy, address prev) public {
        guy.unenroll(prev);
    }

    function perform_add_relayer(Guy guy, address prev, uint fee) public {
        guy.addRelayer(prev, fee);
    }

    function perform_remove_relayer(Guy guy, address prev) public {
        guy.removeRelayer(prev);
    }

    function perform_move_relayer(Guy guy, address old_prev, address new_prev, uint new_fee) public {
        guy.moveRelayer(old_prev, new_prev, new_fee);
    }

    function perform_assign(uint key, uint wad) public {
        market.assign{value: wad}(key);
    }
}

contract Guy {
    FeeMarket market;

    constructor(FeeMarket _market) {
        market = _market;
    }

    receive() payable external {}

    function join() payable public {
        market.deposit{value: msg.value}();
    }

    function exit(uint wad) public {
        market.withdraw(wad);
    }

    function enroll(address prev, uint fee) payable public {
        market.enroll{value: msg.value}(prev, fee);
    }

    function unenroll(address prev) public {
        market.unenroll(prev);
    }

    function addRelayer(address prev, uint fee) public {
        market.addRelayer(prev, fee);
    }

    function removeRelayer(address prev) public {
        market.removeRelayer(prev);
    }

    function moveRelayer(address old_prev, address new_prev, uint new_fee) public {
        market.moveRelayer(old_prev, new_prev, new_fee);
    }
}
