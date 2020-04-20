import  java.net.InetAddress

import rx.Observable
import groovy.json.JsonSlurper

import org.functional4j.rx.Variant

import ch.skyguide.isup.netio.protocol.DriverStatus
import ch.skyguide.isup.netio.protocol.data.Heartbeat
import ch.skyguide.isup.netio.protocol.data.Data
import ch.skyguide.isup.netio.protocol.data.ItemAddressValue
import ch.skyguide.isup.netio.protocol.Serializer

jsonSlurper = new JsonSlurper()
statusRedu = new Variant(DriverStatus.CONNECTED)
hostName = InetAddress.getLocalHost().getHostName();

// shutdown
def shutdown() {
	// send stopped status
	def data = new Data().append(serviceAddress.toString(), DriverStatus.STOPPED.value)
	def msg = Serializer.getInstance().serialize(data)
	mqOutStatus.setValue(msg)

	// shutdown
	outShutdownAction.setValue(true)
}

inWatcher.observable
.filter(value -> value == false)
.subscribe(value -> {
        shutdown()
    }, ERROR::log);

mqInCommand.observable
.subscribe(str -> {
        try {
            json = jsonSlurper.parseText(str)
            if ("${serviceAddress}.command.${hostName}".equalsIgnoreCase(json.address) 
                && "stop".equalsIgnoreCase(json.value)) {
                shutdown()
            }
        } catch (Exception ex) {
            ERROR.log(ex)
        }
    })

// send heartbeat
mqInRedu.observable
.subscribe(str -> {
        try {
            json = jsonSlurper.parseText(str)
            if ("mqtt.active.driver".equalsIgnoreCase(json.address)) {
                out = new Heartbeat().append(serviceAddress.toString())
                mqOutHeartbeat.setValue(Serializer.getInstance().serialize(out))
            }
        } catch (Exception ex) {
            ERROR.log(ex)
        }
    })

// transform mqdriver redu status message
// { "address": "mqtt.active.driver", "value": "1"}
mqInRedu.observable
.subscribe(str -> {
        try {
            json = jsonSlurper.parseText(str)
            if ("mqtt.active.driver".equalsIgnoreCase(json.address)) {
                status = "1".equals(json.value) ? DriverStatus.CONNECTED : DriverStatus.STANDBY
                statusRedu.setValue(status)
            }
        } catch (Exception ex) {
            ERROR.log(ex)
        }
    })
