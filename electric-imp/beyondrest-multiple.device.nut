// FUNCTIONS
function onewireReset() {
    // Configure UART for 1-Wire RESET timing
    ow.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
    ow.write(0xF0);
    ow.flush();
    local read = ow.read();
    if (read == -1) {
        // No UART data at all
        server.log("No circuit connected to UART.");
        return false;
    } else if (read == 0xF0) {
        // UART RX will read TX if there's no device connected
        server.log("No 1-Wire devices are present.");
        return false;
    } else {
        // Switch UART to 1-Wire data speed timing
        ow.configure(115200, 8, PARITY_NONE, 1, NO_CTSRTS);
        return true;
    }
}
 
function onewireWriteByte(byte) {
    for (local i = 0 ; i < 8 ; i++) {
        // Run through the bits in the byte, extracting the
        // LSB (bit 0) and sending it to the bus
        onewireBit(byte & 0x01);
        byte = byte >> 1;		
    }
} 
 
function onewireReadByte() {
    local byte = 0;
    for (local i = 0 ; i < 8 ; i++) {
        // Build up byte bit by bit, LSB first
        byte = (byte >> 1) + 0x80 * onewireBit(1);
    }
    return byte;
}
 
function onewireBit(bit) {
    bit = bit ? 0xFF : 0x00;
    ow.write(bit);
    ow.flush();
    local returnVal = ow.read() == 0xFF ? 1 : 0;
    return returnVal;
}
 
function onewireSearch(nextNode) {
    // 'lastForkPoint' records where the device tree last branched
    local lastForkPoint = 0;
    
    // Reset the bus and exit if no device found
    if (onewireReset()) {
        // There are 1-Wire device(s) on the bus, so issue the 1-Wire SEARCH command (0xF0)
        onewireWriteByte(0xF0);

        // Work along the 64-bit ROM code, bit by bit, from LSB to MSB
        for (local i = 64 ; i > 0 ; i--) {
            local byte = (i - 1) / 8;

            // Read bit from bus
            local bit = onewireBit(1);
            
            // Read the next bit
            if (onewireBit(1)) {
                if (bit) {
                    // Both bits are 1 which indicates that there are no further devices
                    // on the bus, so put pointer back to the start and break out of the loop
                    lastForkPoint = 0;
                    break;
                }
            } else if (!bit) {
                // First and second bits are both 0: we're at a node
                if (nextNode > i || (nextNode != i && (id[byte] & 1))) {
                    // Take the '1' direction on this point
                    bit = 1;
                    lastForkPoint = i;
                }        
            }
        
            // Write the 'direction' bit. For example, if it's 1 then all further
            // devices with a 0 at the current ID bit location will go offline
            onewireBit(bit);
            
            // Write the bit to the current ID record
            id[byte] = (id[byte] >> 1) + 0x80 * bit;
        }
    }
    
    // Return the last fork point so it can form the start of the next search
    return lastForkPoint
}
 
function onewireSlaves() {
    id <- [0,0,0,0,0,0,0,0];
    nextDevice <- 65;
    
    while (nextDevice) {
        nextDevice = onewireSearch(nextDevice);
        
        // Store the device ID discovered by one_wire_search() in an array
        // Nb. We need to clone the array, id, so that we correctly save 
        // each one rather than the address of a single array
        slaves.push(clone(id));
    }
}
 
function getTemp() {
    local tempLSB = 0;
    local tempMSB = 0;
    local tempCelsius = 0;
	// Data from three sensors
	local temp_1 = 1;   
	local temp_2 = 2;
	local temp_3 = 3;
    // Wake up in five minutes for the next reading 
    imp.wakeup(300.0, getTemp);

    // Reset the 1-Wire bus
    local result = onewireReset();
    
    if (result) {
        // Issue 1-Wire Skip ROM command (0xCC) to select all devices on the bus
        onewireWriteByte(0xCC);
    
        // Issue DS18B20 Convert command (0x44) to tell all DS18B20s to get the temperature
        // Even if other devices don't ignore this, we will not read them
        onewireWriteByte(0x44);
    
        // Wait 750ms for the temperature conversion to finish
        imp.sleep(0.75);
    
        foreach (device, slaveId in slaves) {
            // Run through the list of discovered slave devices, getting the temperature
            // if a given device is of the correct family number: 0x28 for BS18B20
            if (slaveId[7] == 0x28) {
                onewireReset();
            
                // Issue 1-Wire MATCH ROM command (0x55) to select device by ID
                onewireWriteByte(0x55);
            
                // Write out the 64-bit ID from the array's eight bytes
                for (local i = 7 ; i >= 0 ; i--) {
                    onewireWriteByte(slaveId[i]);
                }
            
                // Issue the DS18B20's READ SCRATCHPAD command (0xBE) to get temperature
                onewireWriteByte(0xBE);
            
                // Read the temperature value from the sensor's RAM
                tempLSB = onewireReadByte();
                tempMSB = onewireReadByte();
            
                // Signal that we don't need any more data by resetting the bus
                onewireReset();
        
                // Calculate the temperature from LSB and MSB, making sure we
                // sign-extend the signed 16-bit temperature readinf ('raw') 
                // to a Squirrel 32-bit signed integer ('tempCelsius')
                local raw = (tempMSB << 8) + tempLSB;
                tempCelsius = ((raw << 16) >> 16) * 0.0625;
				
				// Sending the data
				local id = hardware.getdeviceid();
				
				if (device == 0) {
				temp_1 = tempCelsius;
				}
				if (device == 1) {
				temp_2 = tempCelsius;
				}
				if (device == 2) {
				temp_3 = tempCelsius;
				}
				local datapoint = {
				    "transmitter_id" : id,
				    "sensors": [
				        {
				            "name": "First Sensor",
				            "temp": format("%.2f",temp_1)
				        },
				        				        {
				            "name": "Second Sensor",
				            "temp": format("%.2f",temp_2)
				        },
				        				        {
				            "name": "Waterproof",
				            "temp": format("%.2f",temp_3)
				        }
				    ]}

				agent.send("event",datapoint);
		
                server.log(format("Device: %02d Family: %02x Serial: %02x%02x%02x%02x%02x%02x Temp: %3.2f", (device + 1), slaveId[7], slaveId[1], slaveId[2], slaveId[3], slaveId[4], slaveId[5], slaveId[6], tempCelsius));
            }
        }
    }
}

// RUNTIME START
// Set up the 1-Wire UART. This is for an imp001 -  
// change the UART object in the line below for other imps
ow <- hardware.uart12;
slaves <- [];
 
// Enumerate the slaves on the bus
onewireSlaves();
 
// Start sampling temperature data
getTemp();