// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";

/*errors*/
error CarPooling__AlreadyServing();
error CarPooling__NotEnoughSlots();
error CarPooling__BookingEnded();
error CarPooling__SendMoreFunds();
error CarPooling__AllSlotOccupied();

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
        address owner;
        string origin;
        string destination;
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
        bool isCompleted;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    /*mappings*/

    // check whether the current user is already giving service or not
    mapping(address => bool) public isServing;

    // map pooling service with carpoolingId
    mapping(uint256 => Pooling) public idToPooling;

    Pooling[] public poolingServices;
    mapping(uint256 => mapping(address => Booking)) public bookingsOfAUser;

    /*functions*/

    // nazimabad, safoora, 4, 100000000000000
    // 100000000000000
    function createCarPooling(
        string memory _origin,
        string memory _destination,
        uint256 _slots,
        uint256 _price
    ) public payable {
        if (isServing[msg.sender] == true) {
            revert CarPooling__AlreadyServing();
        }

        // require(
        //     msg.value == 1e14,
        //     "to start service you need deposit 1e14 ethers collateral amount"
        // );

        _carpoolingIds.increment();
        uint256 newCarpoolId = _carpoolingIds.current();
        Pooling memory newPoolingService = Pooling(
            newCarpoolId,
            msg.sender,
            _origin,
            _destination,
            _slots,
            _price,
            block.timestamp,
            State.accepting
        );
        idToPooling[newCarpoolId] = newPoolingService;
        poolingServices.push(newPoolingService);
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
        bookingsOfAUser[_carpoolingId][msg.sender].isCompleted = false;

        idToPooling[_carpoolingId].slots -= _nSlotsToBook;
    }

    /*getters*/
}

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
