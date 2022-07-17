
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error, result);
            display('Operational Status', 'Check if contract is operational', [{ label: 'Operational Status', error: error, value: result }]);
        });

        contract.airlines.forEach(airline => {
            const element = document.createElement("option");
            element.text = airline;
            element.value = airline;
            DOM.elid("airlines").add(element);
        });  

        contract.flights.forEach(flight => {
            displayListFlight(flight);
        });

        contract.passengers.forEach(passenger => {
            displayListPassenger(passenger);
        });  

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [{ label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp }]);
            });
        });

        DOM.elid('register-airline').addEventListener('click', () => {
            let airline = DOM.elid('address-airline').value;
            contract.registerAirline(airline, (error, result) => {
                if (error) alert(error);
                else {
                    alert("Airline registered successfully!");
                    displayListAirline(airline);
                }
            });
            DOM.elid('address-airline').value = "";
            
        });

        DOM.elid('btn-add-fund-airline').addEventListener('click', () => {
            let address = DOM.elid('airlines').value;
            let fund = DOM.elid('add-fund-airline').value;
            contract.sendFundToAirline(address, fund, (error, result) => {
                if (error) alert(error);
                else alert("Airline funded successfully!");
            });
        });

        DOM.elid('flights').addEventListener('change', () => {
            return contract.flights;
        });

        DOM.elid('airlines').addEventListener('change', () => {
            return contract.airlines;
        });

        DOM.elid('btn-purchase-insurance').addEventListener('click', () => {
            const passenger = DOM.elid('passengers').value;
            const flight = DOM.elid('flights').value;
            const insurance = DOM.elid('purchase-insurance').value;
            if (Number(insurance) > 0) 
                contract.buyInsurance({passenger, insurance, flight}, (error, result) => {
                    if (error) alert(error);
                    else alert("Passenger buy insurance successfully");
                });
            else alert("Please enter eth to buy insurance");
        });

        DOM.elid('show-insurance').addEventListener('click', () => {
            const address = DOM.elid('passenger-insurance-address').value;
            contract.showInsurance(address, (error, result) => {
                alert(result);
           });
            
        });

        DOM.elid('withdraw-insurance').addEventListener('click', () => {
            let passenger = DOM.elid('passenger-withdraw-address').value;
            contract.payInsurance(passenger, (error, result) => {
                if (result) alert("Withdraw successfully!")
           });
        });

    });


})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
        row.appendChild(DOM.div({ className: 'col-sm-8 field-value' }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}

function displayListAirline(address) {
    const element = document.createElement("option");
    element.text = address;
    element.value = address;
    DOM.elid("airlines").add(element);
}

function displayListFlight(flight) {
    const element = document.createElement("option");
    element.text = `${flight.flight} - ${new Date((flight.timestamp))}`;
    element.value = JSON.stringify(flight);
    DOM.elid("flights").add(element);
}

function displayListPassenger(passenger) {
    const element = document.createElement("option");
    element.text = passenger;
    element.value = passenger;
    DOM.elid("passengers").add(element);
}







