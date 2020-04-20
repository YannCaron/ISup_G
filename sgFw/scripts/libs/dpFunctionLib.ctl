anytype connectHeartbeat() {
	return true;
}

anytype connectHeartbeatOPSOnly(anytype status1, anytype status2, anytype status3) {
	if (status1 == "OPS" || status2 == "OPS" || status3 == "OPS") {
		return true;
	} else {
		return removeDoneCB();
	}
}
