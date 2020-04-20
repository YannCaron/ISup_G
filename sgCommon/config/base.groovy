import ch.skyguide.isup.netio.protocol.data.Data
import ch.skyguide.isup.netio.protocol.Serializer

// status
statusRedu.observable
.map(status -> new Data().append(serviceAddress.toString(), status.value))
.map(msg -> Serializer.getInstance().serialize(msg))
.subscribe(mqOutStatus::setValue, ERROR::log)