// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/*errors*/
error CarPooling__AlreadyServing();

contract CarPooling {
    /* Variables  */
    enum State {
        accepting,
        closed
    }

    /*structures*/
    struct Pooling {
        uint64 carpoolingId;
        address payable owner;
        string origin;
        string destination;
        uint8 slots;
        uint256 price;
        uint256 startTime;
        State carpoolingState;
    }

    struct Booking {
        uint64 bookingId;
        address payable user;
        uint8 nSlotBooked;
        bool isCompleted;
    }

    /*mappings*/

    // check whether the current user is already giving service or not
    mapping(address => bool) public isServing;

    // map pooling service with carpoolingId
    mapping(uint256 => Pooling) private idToPooling;

    /*functions*/

    // nazimabad, safoora, 4, 100000000000000
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

        // pooling owner start his service
        isServing[msg.sender] = true;
    }

    /*getters*/
}
