pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    address[] private registeredAirlines;

    struct Airline {
        bool isRegistered;
        uint fund;
    }

    mapping(address => Airline) airlines;

    address[] private consensusOfRegistered;

    struct Passenger {
        bool[] isPaids;
        uint256[] insuranceAmounts;
        string[] flights;
    }

    mapping(address => Passenger) passengers;

    mapping(string => address[]) flightPassengers;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address _address
                                ) 
                                public 
    {
        contractOwner = msg.sender;

        consensusOfRegistered = new address[](0);

        airlines[_address] = Airline({ isRegistered: true, fund: 0 });
        registeredAirlines.push(_address);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address _address
                            )
                            external
                            pure
                            requireIsOperational
    {
        airlines[_address] = Airline({ isRegistered: true, fund: 0 });
        registeredAirlines.push(_address);
    }

    function isExistedAirline(address _address) public view requireIsOperational returns (bool) {
        return airlines[_address].isRegistered;
    }

    function getNumberOfAirlines() public view requireIsOperational returns (uint){
        return registeredAirlines.length;
    }

    function isAirlineFunded(address _address) public view requireIsOperational returns (bool) {
        return airlines[_address].fund >= 10 ether;
    }

    function addConsensusRegistered(address _address) public view requireIsOperational returns (uint){
        consensusOfRegistered.push(_address);
    }

    function clearConsensusRegistered() public {
        consensusOfRegistered = new address[](0);
    }

    function getNumberOfConsensusRegistered() public view requireIsOperational returns (uint){
        return consensusOfRegistered.length;
    }

    function getPassengersInsured(string _flight) external view requireIsOperational returns(address[]){
        return flightPassengers[_flight];
    }

    function getInsureOfFlight(string _flight, address _passenger) external view requireIsOperational returns (uint){
        int index = getIndexOfFlight(_passenger, _flight);

        if(passengers[_passenger].isPaids[index] == false)
            return passengers[_passenger].insuranceAmounts[index];
        
        return 0;
    }

    function setInsureOfFlight(string _flight, address _passenger,uint _amount) external requireIsOperational{
        int index = getIndexOfFlight(_passenger, _flight);
        passengers[_passenger].isPaids[index] = true;
        //insurancePayment[_passenger] = insurancePayment[_passenger].add(_amount);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            ( 
                                address _address,
                                uint256 _price,
                                string _flight                            
                            )
                            external
                            payable
                            requireIsOperational
    {
        if(passengers[_address].flights.length > 0) {
            int index = getIndexOfFlight(_passenger, _flight) ;
            require(index == -1, "Passenger has been insured for this flight");

            passengers[_passenger].isPaids.push(false);
            passengers[_passenger].insuranceAmounts.push(_price);
            passengers[_passenger].flights.push(_flight);

        } else {
           passengers[_address] = Passenger({ isPaids: [false], insuranceAmounts: [_price], flights: [_flight] });
        }

        flightPassengers[_flight].push(_address);

    }

    function getIndexOfFlight(address _address, string memory _flight) public view returns(int)
    {
        string[] memory flights = passengers[_address].flights;

        for(uint i = 0; i < flights.length; i++){
            if(uint(keccak256(abi.encodePacked(flights[i]))) == uint(keccak256(abi.encodePacked(_flight)))) {
                return i;
            }
        }
        return -1;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

