import rx.Observable

import org.functional4j.rx.Variant

import ch.skyguide.isup.netio.protocol.DriverStatus
import ch.skyguide.isup.netio.protocol.data.Heartbeat
import ch.skyguide.isup.netio.protocol.data.Data
import ch.skyguide.isup.netio.protocol.data.ItemAddressValue
import ch.skyguide.isup.netio.protocol.Serializer

import java.util.concurrent.TimeUnit

import org.snmp4j.smi.Integer32
      
def activeServer = new Variant("USpace.ServerA");

def convertUspaceResult(up) {
	if (!(up instanceof Integer32)) {
		LOGGER.warn("Unknown value ${up} of type ${up.getClass()}")
		return "UKN"
	}

	switch (up.toInt()) {
	case 1 : return "OPS"
	case 2 : return "SBY"
	case 3 : return "DEG"
	case 4 : return "U/S"
	default: return "UKN"
    }
}


// determine active server
Observable
.merge(UspaceServerAStatus.observable, UspaceServerBStatus.observable, UspaceServerCStatus.observable)
.map(msg -> msg.ident)
.throttleFirst(9500, TimeUnit.MILLISECONDS)
.subscribe(activeServer::setValue, ERROR::log)

// debug
activeServer.observable
.distinctUntilChanged()
.map(name -> "USpace active server change: ${name}".toString())
.subscribe(LOGGER::info, ERROR::log)

// convert status and send to queue
UspaceSNMPResponse.observable
.filter(msg -> msg.ident.equals(activeServer.value))
.map(data -> new Data().append("uspace.status.${data.node}".toString(), convertUspaceResult(data.value)))
.map(msg -> Serializer.getInstance().serialize(msg))
.subscribe(mqOutData::setValue, ERROR::log)
 