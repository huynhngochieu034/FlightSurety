import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);


flightSuretyApp.events.OracleRequest({
  fromBlock: 'latest'
}, function (error, event) {
  if (error) console.log(error)
  console.log(event)

  const flight = event.returnValues.flight;
  const airline = event.returnValues.airline;
  const timestamp = event.returnValues.timestamp;

  let found = false;

  let selectedCode = {
    label: 'STATUS_CODE_ON_TIME',
    code: 10
  }
  const scheduledTime = (timestamp * 1000);

  if (scheduledTime < new Date().getTime() ) {
    selectedCode = {
      label: 'STATUS_CODE_LATE_AIRLINE',
      code: 20
    }
  }
  oracles.forEach((oracle, index) => {
    if (found) {
      return false;
    }
    for (let idx = 0; idx < 3; idx += 1) {
      if (found) break;
      flightSuretyApp.methods.submitOracleResponse(
        oracle[idx], airline, flight, timestamp, selectedCode.code
      ).send({
        from: accounts[index]
      }).then(rs => {
        found = true;
      }).catch(err => {
        console.log(err);
      });
    }
  });
});

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})

export default app;


