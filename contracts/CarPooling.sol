// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";

/*errors*/
error CarPooling__AlreadyServing();
error CarPooling__NotEnoughSlots();
error CarPooling__BookingEnded();
error CarPooling__SendMoreFunds();
error CarPooling__AllSlotOccupied();
error CarPooling__NoSlotBooked();
error CarPooling__YouAreNotOwner();

contract CarPooling {
    using Counters for Counters.Counter;
    Counters.Counter private _carpoolingIds;
    Counters.Counter private _bookingIds;

    /* Variables  */
    //No need of so many variables in enum State
    // accepting and closed will do the job
    enum State {
        accepting,
        closed
    }

    address payable owner;

    /*structures*/
    struct Pooling {
        uint256 carpoolingId;
        address payable owner;
        string origin;
        string destination;
        uint256 tslots;
        uint256 slots;
        uint256 price;
        uint256 startTime;
        State carpoolingState;
    }

    struct Booking {
        uint256 carpoolingId; // To identify which carpooling is the booking being done on.
        uint256 bookingId;
        address user;
        uint8 nSlotBooked;
        uint256 amountRefund;
        bool isCompleted;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // Booking[] public confirmedBookings; //Keeps a track of current pending orders.
    Booking[] public cancelledBookings;

    /*mappings*/
    mapping(uint256 => Booking[]) public poolingToBooking;

    // check whether the current user is already giving service or not
    mapping(address => bool) private isServing;

    // map pooling service with carpoolingId
    mapping(uint256 => Pooling) public idToPooling;

    // Pooling[] public poolingServices;

    mapping(uint256 => mapping(address => Booking)) public bookingsOfAUser;

    /*functions*/

    // nazimabad, safoora, 4, 100000000000000
    // collateral: 100000000000000
    // 	0x20775d300BdE943Ac260995E977fb915fB01f399
    function createCarPooling(
        string memory _origin,
        string memory _destination,
        uint256 _slots,
        uint256 _price
    ) public payable {
        if (isServing[msg.sender] == true) {
            revert CarPooling__AlreadyServing();
        }

        require(
            msg.value == 1e14,
            "to start service you need deposit 1e14 ethers collateral amount"
        );

        _carpoolingIds.increment();
        uint256 newCarpoolId = _carpoolingIds.current();
        Pooling memory newPoolingService = Pooling(
            newCarpoolId,
            payable(msg.sender),
            _origin,
            _destination,
            _slots,
            _slots,
            _price,
            block.timestamp,
            State.accepting
        );
        idToPooling[newCarpoolId] = newPoolingService;

        // poolingServices.push(newPoolingService);

        // pooling owner start his service
        isServing[msg.sender] = true;
    }

    function BookCarpooling(uint256 _carpoolingId, uint8 _nSlotsToBook)
        public
        payable
    {
        if (idToPooling[_carpoolingId].slots <= 0) {
            revert CarPooling__AllSlotOccupied();
        }

        if (idToPooling[_carpoolingId].slots < _nSlotsToBook) {
            revert CarPooling__NotEnoughSlots();
        }

        if (msg.value < idToPooling[_carpoolingId].price * _nSlotsToBook) {
            revert CarPooling__SendMoreFunds();
        }

        if (idToPooling[_carpoolingId].carpoolingState == State.closed) {
            revert CarPooling__BookingEnded();
        }

        _bookingIds.increment();
        uint256 newBookingId = _bookingIds.current();
        bookingsOfAUser[_carpoolingId][msg.sender].carpoolingId = _carpoolingId;
        bookingsOfAUser[_carpoolingId][msg.sender].bookingId = newBookingId;
        bookingsOfAUser[_carpoolingId][msg.sender].user = msg.sender;
        bookingsOfAUser[_carpoolingId][msg.sender].nSlotBooked += _nSlotsToBook;

        idToPooling[_carpoolingId].slots -= _nSlotsToBook;
        bookingsOfAUser[_carpoolingId][msg.sender].isCompleted = false;
        // (bool success, ) = idToPooling[_carpoolingId].owner.call{
        //     value: msg.value
        // }("");
        // require(success, "Transfer failed");

        // confirmedBookings.push(bookingsOfAUser[_carpoolingId][msg.sender]);
        poolingToBooking[_carpoolingId].push(
            bookingsOfAUser[_carpoolingId][msg.sender]
        );

        // idToPooling[_carpoolingId].slots -= _nSlotsToBook;
    }

    function cancelBooking(uint256 _carpoolingId, uint8 _nSlotsToCancel)
        public
        payable
    {
        if (bookingsOfAUser[_carpoolingId][msg.sender].nSlotBooked <= 0) {
            revert CarPooling__NoSlotBooked();
        }
        bookingsOfAUser[_carpoolingId][msg.sender]
            .nSlotBooked -= _nSlotsToCancel;
        idToPooling[_carpoolingId].slots += _nSlotsToCancel;
        bookingsOfAUser[_carpoolingId][msg.sender].amountRefund =
            idToPooling[_carpoolingId].price *
            _nSlotsToCancel;
        (bool success, ) = msg.sender.call{
            value: bookingsOfAUser[_carpoolingId][msg.sender].amountRefund
        }("");
        require(success, "Transfer failed");
    }

    function completeRide(uint256 _carpoolingId) public payable {
        if (idToPooling[_carpoolingId].owner != msg.sender) {
            revert CarPooling__YouAreNotOwner();
        }

        idToPooling[_carpoolingId].carpoolingState = State.closed;

        // calc 10% fee
        uint256 fee = 100000000000000 / 10;

        (bool success, ) = idToPooling[_carpoolingId].owner.call{
            value: ((idToPooling[_carpoolingId].tslots -
                idToPooling[_carpoolingId].slots) *
                idToPooling[_carpoolingId].price) + (100000000000000 - fee)
        }("");
        require(success, "Transfer failed");

        // //send user's collateral minus fee
        // (bool success, ) = idToPooling[_carpoolingId].owner.call{
        //     value: refund
        // }("");
        // require(success, "Transfer failed");

        idToPooling[_carpoolingId].slots = 4;

        isServing[msg.sender] = false;
    }

    /*getters*/

    function getIsServing(address _carPooler) external view returns (bool) {
        return isServing[_carPooler];
    }

    function getIdToPooling(uint256 _carpoolId)
        external
        view
        returns (Pooling memory)
    {
        return idToPooling[_carpoolId];
    }

    function getBookingsOfAUser(uint256 _carpoolId, address _user)
        external
        view
        returns (Booking memory)
    {
        return bookingsOfAUser[_carpoolId][_user];
    }

    function getAllconfirmedBookings(uint256 _carpoolId)
        external
        view
        returns (Booking[] memory)
    {
        return poolingToBooking[_carpoolId];
    }

    function servingState(address user) external view returns (bool) {
        return isServing[user];
    }

    function getUserAmountRefund(uint256 id, address user)
        external
        view
        returns (uint256)
    {
        return bookingsOfAUser[id][user].amountRefund;
    }
}
