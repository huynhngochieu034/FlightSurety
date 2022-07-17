pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    mapping(address => uint256) private authorizedCallers;

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Airline {
        bool isRegistered;
        uint256 fund;
    }

    mapping(address => Airline) airlines;
    address[] private registeredAirlines;

    address[] private consensusOfRegistered;


    struct Passenger {
        bool[] isPaids;
        uint256[] insuranceAmounts;
        string[] flights;
    }

    mapping(address => Passenger) passengers;

    mapping(string => address[]) flightPassengers;

    mapping(address => uint256) private insurancePayments;

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

        airlines[_address] = Airline({ isRegistered: true, fund: 0});
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

    modifier requireIsCallerAuthorized()
    {
        require(authorizedCallers[msg.sender] == 1, "Caller is not contract owner");
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

    function authorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedCallers[contractAddress] = 1;
    }

    function deauthorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedCallers[contractAddress];
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
                            requireIsOperational
    {
        if(airlines[_address].isRegistered) {

        } else {
          airlines[_address] = Airline ({ isRegistered: true, fund: 0 });
          registeredAirlines.push(_address);
        }
        
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

    function addConsensusRegistered(address _address) public requireIsOperational returns (uint){
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
        uint256 index = getIndexOfFlight(_passenger, _flight) - 1;

        if(passengers[_passenger].isPaids[index] == false)
            return passengers[_passenger].insuranceAmounts[index];
        
        return 0;
    }

    function setInsureOfFlight(string _flight, address _address,uint _amount) external requireIsOperational{
        uint256 index = getIndexOfFlight(_address, _flight) - 1;
        passengers[_address].isPaids[index] = true;
        insurancePayments[_address] = insurancePayments[_address].add(_amount);
    }

    function getInsurancePayment(address _address) external view requireIsOperational returns (uint){
        return insurancePayments[_address];
    }

    function getRegisteredAirlines() requireIsOperational public view returns(address[]){
        return registeredAirlines;
    }

    function setInsurancePayment(address _address) external requireIsOperational{
        insurancePayments[_address] = 0;
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
            uint256 index = getIndexOfFlight(_address, _flight) ;
            require(index == 0, "Passenger has been insured for this flight");

            passengers[_address].isPaids.push(false);
            passengers[_address].insuranceAmounts.push(_price);
            passengers[_address].flights.push(_flight);

        } else {
            string[] memory flights = new string[](3);
            bool[] memory isPaids = new bool[](3);
            uint256[] memory insuranceAmounts = new uint[](3);

            isPaids[0] = false;
            insuranceAmounts[0] = _price;
            flights[0] = _flight;

           passengers[_address] = Passenger({ isPaids: isPaids, insuranceAmounts: insuranceAmounts, flights: flights });
        }

        flightPassengers[_flight].push(_address);

        insurancePayments[_address] = _price;
    }

    function getIndexOfFlight(address _address, string memory _flight) public view returns(uint256)
    {
        string[] memory flights = passengers[_address].flights;

        for(uint i = 0; i < flights.length; i++)
            if(uint(keccak256(abi.encodePacked(flights[i]))) == uint(keccak256(abi.encodePacked(_flight)))) 
                return i + 1;
            
        return 0;
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
    // function pay
    //                         (
    //                             uint funds
    //                         )
    //                         external
    //                         requireIsOperational
    // {
    //     if(address(this).balance > funds){
    //         msg.sender.transfer(funds);
    //     }
    // }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address _address,
                                uint256 _fund
                            )
                            public
                            payable
    {
        airlines[_address].fund = airlines[_address].fund.add(_fund);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    // function() 
    //                         external 
    //                         payable 
    // {
      
    // }


}

