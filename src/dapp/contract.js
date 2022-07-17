import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.flights = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts(async (error, accts) => {

            this.owner = accts[0];

            let counter = 0;

            this.airlines = await this.flightSuretyApp.methods.getRegisteredAirlines().call({ from: self.owner});

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            while (this.flights.length < 5) {
                this.flights.push({
                    airline: accts[counter],
                    flight: "Flight " + counter++,
                    timestamp: randomDate(new Date(2022, 6, 17), new Date())
                });  
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner }, (error, result) => {
                callback(error, payload);
            });
    }

    async registerAirline(airline, callback) {
        let self = this;
        await self.flightSuretyApp.methods.registerAirline(airline).send({ from: self.owner, gas:"999999"}, (error, result) => {
            callback(error, result);
        });
    }

    async getRegisteredAirlines(callback) {
        const self = this;
        await self.flightSuretyApp.methods.getRegisteredAirlines().call({}, (error, result) => {
            callback(error, result);
        });
    }

    async sendFundToAirline(address, fund, callback) {
        const self = this;
        const amount = `${self.web3.utils.toWei(fund, "ether")}`;
        await self.flightSuretyApp.methods.sendFundToAirline(address).send({ from: self.owner, value: amount }, (error, result) => {
            callback(error, result);
        });
    }

    async buyInsurance(value, callback){
        let self = this;
        const amount = self.web3.utils.toWei(value.insurance, "ether").toString();

        await self.flightSuretyApp.methods.buyInsurance(value.insurance, value.flight).send({ from: value.passenger, value: amount,  gas:"999999" }, (error, result) => {
                callback(error, result);
            });
    }

    async showInsurance(passenger, callback){
        let self = this;
        await self.flightSuretyApp.methods.getPassengersInsurance().call({from: passenger}, (error, result) => {
            callback(error, result);
        });
    }

    async payInsurance(passenger, callback){
        let self = this;
        const fund =  await self.flightSuretyApp.methods.getPassengersInsurance().call({from: passenger}, (error, result) => {
            return result;
        });
        const amount = self.web3.utils.toWei(fund, "ether").toString();
        await self.flightSuretyApp.methods.payInsurance(amount).send({from: passenger, gas: "300000"}, (error, result) => {
            callback(error, result);
        });
    }


}