import org.functional4j.rx.Variant
import ch.skyguide.isup.netio.protocol.DriverStatus
import ch.skyguide.isup.netio.protocol.data.Heartbeat
import ch.skyguide.isup.netio.protocol.data.Data
import ch.skyguide.isup.netio.protocol.data.ItemAddressValue
import ch.skyguide.isup.netio.protocol.Serializer

def statusResult = new Variant(DriverStatus.INITIALIZE)
def host = java.net.InetAddress.getLocalHost().getHostName()

// zip status and redu to consolidate final status
// send { "address": "1", "value": "OPS"}
rx.Observable
.combineLatest(statusResult.observable, statusRedu.observable, (status, redu) -> status == DriverStatus.CONNECTED ? redu : status)
.map(status -> new Data().append(serviceAddress.toString(), status.value))
.map(msg -> Serializer.getInstance().serialize(msg))
.subscribe(mqOutStatus::setValue)

// transform active mq JMX message to status
// receive JMXMessage ( node="org.apache.activemq.Broker.localhost.Health.CurrentStatus", value="Good" )
activeMQStatus.observable
.filter (msg -> "org.apache.activemq.Broker.localhost.Health.CurrentStatus".equalsIgnoreCase(msg.node))
.map(msg -> "Good".equalsIgnoreCase(msg.value) ? DriverStatus.CONNECTED : DriverStatus.DISCONNECTED)
.subscribe(statusResult::setValue);

// send active mq JMX message to periphery node
activeMQStatus.observable
.filter (msg -> "org.apache.activemq.Broker.localhost.Health.CurrentStatus".equalsIgnoreCase(msg.node))
.map(msg -> new Data().append("jmx.status.${host}.Health".toString(), msg.value))
.map(msg -> Serializer.getInstance().serialize(msg))
.subscribe(mqOutData::setValue);
