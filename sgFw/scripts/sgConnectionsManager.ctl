int currentTransaction = -1;
main()
{	
	int nextTransaction = 0;

	int socketId;
	
	sgDBWaitForInit();	
	
	bool b;
	
	b = sgProcessorsLibInit();
	if(!b)
		return;
	
	string statusDpName;
	string aliveDpName;
	string activeChain;
	string lastActiveChain;
	string thisChain;
	
	if(isServerA(getHostname()))
	{
		thisChain = "A";
		statusDpName = "ConnectionsManager.InterfaceA.Status.PreStatus";
		aliveDpName = "ConnectionsManager.InterfaceA.Alive";
	}
	else if(isServerB(getHostname()))
	{
		thisChain = "B";
		statusDpName = "ConnectionsManager.InterfaceB.Status.PreStatus";
		aliveDpName = "ConnectionsManager.InterfaceB.Alive";
	}	
	
	
	// Get socketsManager params
	string ipAddress;
	int port;
	char delimiter;
	dpGet("ConnectionsManager.Interface" + thisChain + ".HostAddress", ipAddress);
	dpGet("ConnectionsManager.Config.AsciiDelimiter", delimiter);			
	dpGet("ConnectionsManager.Config.PVSSSocketsManagerPort", port);
		
	while(true)
	{
	
		sgProcessorsCloseAll();
		currentTransaction = -1;
		delay(1);
		if (isLinux()) {  // 2018-11-01 PWU&YCA no Socket used for ISup
			startJavaApp();  
			delay(1);

			// DebugTN("sgConnectionsManager: will connect to sockets manager");
			socketId = tcpOpen(ipAddress, port);
			dpSet(aliveDpName, true);		
			if(socketId == -1)
			{
				DebugTN("sgConnectionsManager: unable to connect to the sockets manager (Java app)");
				dpSet(statusDpName, U_S_STATUS);
				continue;
			}
		}
		dpGet("FwUtils.Framework.ActiveChain", activeChain);
		if(thisChain == activeChain)
		{
			dpSet(statusDpName, OPS_STATUS);
		}
		else
		{
			dpSet(statusDpName, SBY_STATUS);
		}
		
		lastActiveChain = activeChain;	
		dpSet(aliveDpName, true);
		time lastAliveTime = getCurrentTime();

		// put it outside of the loop !! aj 21.03
		// otherwise splitted messages are not treated correctly
		string buffer = "";

		while(socketId != -1)
		{
			// read message from sockets manager

			//put it outside of the loop!! aj 21.03
			// otherwise splitted messages are not treated correctly
			//string buffer = "";

			string read;
			time timeout = 3;
			int res;
			res  = tcpRead(socketId, read, timeout); 
			//DebugTN("sgConnectionsManager: : " + " tcp read return: " + res);
			
			// DebugTN("sgConnectionsManager: message received");
			if(read == "")
			{
				//DebugTN("sgConnectionsManager : we assume socket to socketsManager is lost");
				tcpClose(socketId);
				socketId = -1;
				dpSet(statusDpName, U_S_STATUS);
				activeChain = "";
				break;
			}

			// DebugTN("sgConnectionsManager >> " + read);
	
			buffer = buffer + read;
			dyn_string messages;
	
			if(strpos(buffer, delimiter) != -1)
			{
				messages = strsplit(buffer, delimiter);
				if(buffer[strlen(buffer) - 1] == delimiter) // some full messages
				{
					buffer = "";
				}
				else
				{
					buffer = messages[dynlen(messages)];
					dynRemove(messages, dynlen(messages));

				}
			}
			
			// ensure we do it even if there is no message
			// 20070201 aj changed check to "4" instead of "5" to be on the safe side
			if((getCurrentTime() - lastAliveTime) > 4)
			{
				dpSet(aliveDpName, true);
				lastAliveTime = getCurrentTime();
			}
					
			// 20070201 aj changed check to "4" instead of "5" to be on the safe side
			for(int cpt = 1; cpt <= dynlen(messages); cpt++)
			{
			
				processMessage(messages[cpt]);
				if((getCurrentTime() - lastAliveTime) > 4)
				{
					dpSet(aliveDpName, true);
					lastAliveTime = getCurrentTime();
				}
			}
			
			string currentStatus;
			dpGet("FwUtils.Framework.ActiveChain", activeChain,
						statusDpName, currentStatus);
			
			// VL: 24-JUN-2005: added this check to re-write status in case of timeout after a switchover			
			if(isUKN(currentStatus))
			{
				if(thisChain == activeChain)
				{
					dpSet(statusDpName, OPS_STATUS);
				}
				else
				{
					dpSet(statusDpName, SBY_STATUS);
				}
			}
						
			if(lastActiveChain != activeChain)
			{
				if(thisChain == activeChain)
				{
					dpSet(statusDpName, OPS_STATUS);
				}
				else
				{
					break;
				}
				lastActiveChain = activeChain;				
			}
			
			
			if((thisChain == activeChain) && (currentTransaction == -1))
			{
				dyn_string pendingTransactions;
				pendingTransactions = sgDBTableKeys(DBKEY_TRANS_BUFFER);
				if(dynlen(pendingTransactions) == 0)
				{
					buildTransactions();
				}
				else
				{
					// send next transaction
					dyn_string ds;
					int nextTransaction;
					ds = sgDBTableKeys(DBKEY_TRANS_BUFFER);
					nextTransaction = ds[1];

					ds = sgDBGet(DBKEY_TRANS_BUFFER, nextTransaction);
					bool needAck;
					needAck = ds[3];
					
					tcpWrite(socketId, ds[1] + delimiter);					
					
					if(!needAck)
					{
						sgDBRemove(DBKEY_TRANS_BUFFER, nextTransaction);
						currentTransaction = -1;
					}
					else
					{
						currentTransaction = nextTransaction;
					}
				}
			}
			
		}
		
		if(socketId != -1)
		{
			tcpClose(socketId);
		}
	}
}

void startJavaApp()
{
	int timeOut, socketManagerPort;
	string logPath, consoleLoggerLevel, fileLoggerLevel, pVSSSocketsManagerDelimiter;
	
	dpGet("ConnectionsManager.Config.PVSSSocketsManagerPort", socketManagerPort,
		"ConnectionsManager.Config.TimeOut", timeOut, 
	    	"ConnectionsManager.Config.AsciiDelimiter", pVSSSocketsManagerDelimiter, // for LF : 10
		"FwUtils.LogsPath", logPath);

	consoleLoggerLevel = getConfigValue("ConsoleLoggerLevel");
	fileLoggerLevel = getConfigValue("FileLoggerLevel");
	DebugTN("sgFwSocketsInterface startApplication >> launch the java application with: port: " + socketManagerPort + " timeOut: " + timeOut + " ascii delimiter: " + pVSSSocketsManagerDelimiter +  " logPath: " + logPath +  " console log level: " + consoleLoggerLevel + " file log level: " + fileLoggerLevel);
 	        
	string parameters = socketManagerPort + " " + timeOut + " " + pVSSSocketsManagerDelimiter + " " + logPath + " " + consoleLoggerLevel + " " + fileLoggerLevel;
	
	string cmd;

	if (isLinux()) {
		cmd = "gnome-terminal -e '/project/batches/PVSSSocketsManager.sh " + parameters + "' &";
	} else {
		system ("start /wait taskkill /IM java.exe /F");
		cmd = "start cmd /k d:\\batches\\PVSSSocketsManager.bat " + parameters;
	}

	system (cmd);
}

bool processMessage(string xmlMessage)
{
	dyn_dyn_string xmls;
	int offset;

	//DebugTN("connectionsManager: message received " + xmlMessage);
		
	xmls = XMLsplit(xmlMessage);
	bool find = false;
	
	for (int cpt = 1; cpt <= dynlen(xmls); cpt++)
	{
		if (!XMLcheckStructure(xmls[cpt]))
		{
			sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgSocketManagerMessageInterpreter >> invalid messagereceived from socketsManager: " + xmls[cpt]);	
//			DebugTN("sgSocketManagerMessageInterpreter >> invalid messagereceived from socketsManager: " + xmls[cpt]);	
			return false;
		}	
		
		dyn_int indexes;
		dyn_string subTag;
		
		// heartbeat
		indexes = XMLfindTagIndex(xmls[cpt], HEARTBEAT_TAG);
		for (offset = 1; offset <= dynlen(indexes); offset++)
		{	
			// DebugTN("sgConnectionsManager: received heartbeat");
			find = true;
		}
						
		// Listen acknowledge
		indexes = XMLfindTagIndex(xmls[cpt], LISTEN_ACK_TAG);
		for (offset = 1; offset <= dynlen(indexes); offset++)
		{
			subTag = XMLextractSubTag(xmls[cpt], PORT_TAG, offset);
			
			int port = subTag[2];
			subTag = XMLextractSubTag(xmls[cpt], STATUS_TAG, offset);			
			
			string statusString = strtoupper(subTag[2]);
			
			int transactionId = XMLgetTagProperty(xmls[cpt], TRANSACTION_ID);
			
			bool status = false;
			if (statusString == "TRUE")
				status = true;
				
//			DebugTN("sgConnectionsManager >> ListenAcknowledge receive port: " + port + " with status: " + status);//
			find = true;
			
			if(transactionId != currentTransaction)
			{
//				DebugTN("sgConnectionsManager: listenAck: transactionId mismatch");
				return false;
			}

			// retreive processor
			string processorName;
			processorName = getProcessorNameFromTransaction(transactionId);
			if(processorName == "")
			{
//				DebugTN("sgConnectionsManager: listenAck: unknown processor for transaction " + transactionId);
				return false;
			}

			if(status) // open
			{
					sgDBSet(processorName, DBKEY_PROC_STATUS, PROC_STATUS_OPEN);
			}
			else
			{
					dyn_string empty;
//					DebugTN("Processor " + processorName + " is now closed");
					sgDBSet(processorName, DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
					sgDBSet(processorName, DBKEY_CONNECTION_ID, empty);
			}

			sgDBRemove(DBKEY_TRANS_BUFFER, transactionId);
			currentTransaction = -1;

			
		}	
		
		// Message received
		indexes = XMLfindTagIndex(xmls[cpt], MESSAGE_RECEIVED_TAG);	
		bool isFromServer = false;
		for (offset = 1; offset <= dynlen(indexes); offset++)
		{	
			subTag = XMLextractSubTag(xmls[cpt], CONNECTION_ID_TAG, offset);
			
			int connectionId = subTag[2];

//			DebugTN("Connections manager: message received, connection id " + connectionId);
			
			string processorName;
			processorName = getProcessorNameFromConnection(connectionId);
                        //DebugTN("sgConnectionsManager proc from connid",processorName,connectionId);
			
			if(processorName == "")
			{
				int port;
				subTag = XMLextractSubTag(xmls[cpt], PORT_TAG, offset);
				int port = subTag[2];
				processorName = getProcessorNameFromPort(port);
                                //DebugTN("sgConnectionsManager proc from port",processorName,port,connectionId);
				if(processorName == "")
				{
//					DebugTN("sgConnectionsManager: received message for unknown processor, connection id " + connectionId + " message was " + xmlMessage);
					return false;
				}
				isFromServer = true;
			}	

//			DebugTN("Connections manager: message received, processorName " + processorName + " isServer " + isFromServer);


			bool isXML;
			dyn_string ds;
			
			ds = sgDBGet(processorName, DBKEY_IS_XML);
			isXML = ds[1];
			subTag = XMLextractSubTag(xmls[cpt], MESSAGE_TAG, offset);
							
			string messageReceived;
			
//			DebugTN("Connections manager: received message for processor " + processorName);
//			DebugTN("    size of message subtag: " + dynlen(subTag));
//			DebugTN("    message string is " + xmlMessage);

										
//			if (isXML(port))  TEMP WE ASSUME THAT ALL MESSAGES ARE NON XML CONTENT
			if (isXML)
			{
				string xmlString;
				xmlString = XMLaddHeader("");			

				
				for(int cptTag = 3; cptTag <= (dynlen(subTag) - 1); cptTag++) // special condition to remove tag "MESSAGE FROM SYSTEM"
				{
					xmlString += subTag[cptTag];
				}
				messageReceived = xmlString;
								
			}
			else
			{
					messageReceived = subTag[2];
			}			
			
			if(isFromServer)
			{
				// 20090327 aj try to avoid xml out of range messages
                                // add connectionId and message in one go (atomic) to avoid reading/deleting in between
                                // new function to add multiple elements in sgDB - sgDBAppendMultiple()
                                // sgDBAppend(processorName, DBKEY_MESSAGES_IN, connectionId); // old code
                                // adding strings with pipe works but not nice to add it here -> new function
                                // messageReceived = connectionId + "|" + messageReceived;
                                //DebugTN("sgConnectionsManager isfromserver add connid",processorName,connectionId);

				
				dyn_string currentConnections;
				
				currentConnections = sgDBGet(processorName, DBKEY_CONNECTION_ID);
				
				if(!dynContains(currentConnections, connectionId))
				{
					dynAppend(currentConnections, connectionId);
					sgDBSet(processorName, DBKEY_CONNECTION_ID, currentConnections);
				}

                                dyn_string connIDMessage = makeDynString(connectionId, messageReceived);				
                                sgDBAppendMultiple(processorName, DBKEY_MESSAGES_IN, connIDMessage);
                                
			}
                        else // if not "isFromServer" do as before with normal sgDBAppend
                        {
			  sgDBAppend(processorName, DBKEY_MESSAGES_IN, messageReceived);
                          //DebugTN("sgConnectionsManager whatever add message",processorName,messageReceived);
  //				sgSocketMessageReceived(port, connectionId, messageReceived);
                        }
			find = true;
		}
		
		// Message acknowledge
		
		
		indexes = XMLfindTagIndex(xmls[cpt], MESSAGE_ACK_TAG);	
		for (offset = 1; offset <= dynlen(indexes); offset++)
		{			
			subTag = XMLextractSubTag(xmls[cpt], CONNECTION_ID_TAG, offset);
			int connectionId = subTag[2];

			string processorName;
			processorName = getProcessorNameFromConnection(connectionId);
			if(processorName == "")
			{
//				DebugTN("connections manager: received send message ack for an already closed connection " + connectionId);
				currentTransaction = -1;
				return false;
			}
			
			subTag = XMLextractSubTag(xmls[cpt], STATUS_TAG, offset);
			string statusString = strtoupper(subTag[2]);
			bool status = false;
			if (statusString ==  "TRUE")
				status = true;
			
			int transactionId = XMLgetTagProperty(xmls[cpt], TRANSACTION_ID);
	
//			DebugTN("sgConnectionsManager>> received message aknowledge, transaction " + transactionId);	
			if(transactionId != currentTransaction)
			{
// 				 DebugTN("sgConnectionsManager: messageAck: transactionId mismatch: " + transactionId + " vs. " + currentTransaction);
//				 DebugTN("  status of message ack: " + status);
				 return false;
			}
//			sgSocketReceiveMessageAcknowledge(transactionId, connectionId, status);

			sgDBRemove(DBKEY_TRANS_BUFFER, transactionId);
			currentTransaction = -1;

			find = true;
		}
		
		// ConnectionClosed
		indexes = XMLfindTagIndex(xmls[cpt], CONNECTION_CLOSED_TAG);	
		for (offset = 1; offset <= dynlen(indexes); offset++)
		{
			subTag = XMLextractSubTag(xmls[cpt], CONNECTION_ID_TAG, offset);
//			if (!dynlen(subTag))
//				DebugTN("sgConnectionsManager >> received listen ack without connectionId xml: " + xmls[cpt]);
				
			int connectionId = subTag[2];

			

			// find processor
			string processorName;
			processorName = getProcessorNameFromConnection(connectionId);
			if(processorName == "")
			{
//				DebugTN("sgConnectionsManager >> connection closed for unknown processor, connection id " + connectionId);
				return false;
			}
//			DebugTN("sgConnectionsManager >> Receive from SocketsManager ConnectionClosed for connectionId: " + connectionId);
			
			dyn_string servers;
			
			servers = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST);
			if(dynContains(servers, processorName))
			{
				dyn_string currentConnections;
				bool knownConnection = false;
				
				currentConnections = sgDBGet(processorName, DBKEY_CONNECTION_ID);
				if(dynContains(currentConnections, connectionId))
				{
					dynRemove(currentConnections, dynContains(currentConnections, connectionId));
					sgDBSet(processorName, DBKEY_CONNECTION_ID, currentConnections);
					knownConnection = true;
				}
				
				currentConnections = sgDBGet(processorName, DBKEY_CONNECTIONS_TO_CLOSE);
				if(dynContains(currentConnections, connectionId))
				{
					dynRemove(currentConnections, dynContains(currentConnections, connectionId));
					sgDBSet(processorName, DBKEY_CONNECTIONS_TO_CLOSE, currentConnections);
					knownConnection = true;
				}
		
//				if(!knownConnection)
//				{
//					DebugTN("Connections manager: unknwon connection " + connectionId + " closed from server " + processorName);
//				}

				// remove pending transactions on this connection
				dyn_string allTransactions = sgDBTableKeys(DBKEY_TRANS_BUFFER);
				for(int cptPending = 1; cptPending <= dynlen(allTransactions); cptPending++)
				{
					dyn_string ds;
					ds = sgDBGet(DBKEY_TRANS_BUFFER, allTransactions[cptPending]);
					if(ds[4] == connectionId)
					{
//						DebugTN("Connections manager: remove transaction " + allTransactions[cptPending] + "(" + ds[1] + ") because its connection is closed");
						sgDBRemove(DBKEY_TRANS_BUFFER, allTransactions[cptPending]);
						if(allTransactions[cptPending] == currentTransaction)
						{
//							DebugTN("Connections manager: transaction " + allTransactions[cptPending] + " was current transaction");
							currentTransaction = -1; // avoid waiting for a message ack if connection is closed in between
						}
					}
				}
				
				
			}
			else // client
			{
				dyn_string empty;
				sgDBSet(processorName, DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
				sgDBSet(processorName, DBKEY_CONNECTION_ID, -1);
				sgDBSet(processorName, DBKEY_MESSAGES_IN, empty);
				sgDBSet(processorName, DBKEY_MESSAGES_OUT, empty);
				
				// remove pending transaction of this processor
				dyn_string allTransactions = sgDBTableKeys(DBKEY_TRANS_BUFFER);
				for(int cptPending = 1; cptPending <= dynlen(allTransactions); cptPending++)
				{
					dyn_string ds;
					ds = sgDBGet(DBKEY_TRANS_BUFFER, allTransactions[cptPending]);
					if(ds[2] == processorName)
					{
						sgDBRemove(DBKEY_TRANS_BUFFER, allTransactions[cptPending]);
						if(allTransactions[cptPending] == currentTransaction)
							currentTransaction = -1; // avoid waiting for a message ack if connection is closed in between
					}
				}
			}
			find = true;
		}
		

		
		// Connect acknowledge (socket client)
		indexes = XMLfindTagIndex(xmls[cpt], CONNECT_ACK_TAG);	
		for (offset = 1; offset <= dynlen(indexes); offset++)
		{
			int transactionId = XMLgetTagProperty(xmls[cpt], TRANSACTION_ID);
			
			// DebugTN("sgSocketManagerMessageInterpreter >> ConnectionAcknowledge transaction: " + transactionId);//
						
			subTag = XMLextractSubTag(xmls[cpt], PORT_TAG, offset);
			if (dynlen(subTag) < 2)
			{
				DebugN("sgConnectionsManager >> PORT_TAG not found!");
				return false;
			}
				
			int port = subTag[2];
			
			subTag = XMLextractSubTag(xmls[cpt], IP_ADDRESS_TAG, offset);
			if (dynlen(subTag) < 2)
			{
//				DebugN("sgConnectionsManager >> IP_ADDRESS_TAG not found! message received:\n" + xmlMessage);
				return false;
			}
			
			string IPAddress = subTag[2];
			
			subTag = XMLextractSubTag(xmls[cpt], CONNECTION_ID_TAG, offset);
			if (dynlen(subTag) < 2)
			{
//				DebugN("sgConnectionsManager >> CONNECTION_ID_TAG not found!");
				return false;
			}
			
			int connectionId = subTag[2];
			
			subTag = XMLextractSubTag(xmls[cpt], STATUS_TAG, offset);
			if (dynlen(subTag) < 2)
			{
				DebugN("sgConnectionsManager >> STATUS_TAG not found!");
				return false;
			}
			
			string statusString = strtoupper(subTag[2]);
			
			bool status = false;
			if (statusString == "TRUE")
				status = true;
	
//			DebugTN("sgConnectionsManager: received connectAcknowledge for transaction " + transactionId);	
			
//			(transactionId, port, IPAddress, connectionId, status);

			if(transactionId != currentTransaction)
			{
					sgHistoryAddEvent("FwUtils.SystemHistory", SEVERITY_SYSTEM, "sgConnectionsManager: connectAck: transactionId mismatch: should be " + currentTransaction + ", is " + transactionId + 
					" IPAddress: " + IPAddress + "port: " + port + " connectionId: " + connectionId);
				return false;
			}

			// retreive processor
			string processorName;
			processorName = getProcessorNameFromTransaction(transactionId);
			if(processorName == "")
			{
//				DebugTN("sgConnectionsManager: connectAck: unknown processor for transaction " + transactionId);
				return false;
			}

			if(status) // ready
			{
					sgDBSet(processorName, DBKEY_PROC_STATUS, PROC_STATUS_READY);
					sgDBSet(processorName, DBKEY_CONNECTION_ID, connectionId);
			}
			else
			{
//					DebugTN("Processor " + processorName + " is now closed");
					sgDBSet(processorName, DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
					sgDBSet(processorName, DBKEY_CONNECTION_ID, -1);
			}

			sgDBRemove(DBKEY_TRANS_BUFFER, transactionId);
			currentTransaction = -1;

		  find = true;
		}
			 
	 if (find == false)
	 {
//		DebugTN("sgConnectionsManager >> unexpected message from socketsManager: " + xmls[cpt]);
		return false;
	 }
	} // loop on xml messages
	return true;
}

string getProcessorNameFromPort(int port)
{
		dyn_string ds;
		ds = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST);		
		for(int cpt = 1; cpt <= dynlen(ds); cpt++)
		{
			dyn_string temp;
			temp = sgDBGet(ds[cpt], DBKEY_SERVER_PORT);			
			if(temp[1] == port)
			{
				return ds[cpt];
			}
		}
		return "";
}


string getProcessorNameFromTransaction(int transactionId)
{
		dyn_string ds;
		ds = sgDBGet(DBKEY_TRANS_BUFFER, transactionId);		
		if(dynlen(ds) == 0)
			return "";
			
		return ds[2];
}

string getProcessorNameFromConnection(int connectionId)
{
		dyn_string ds;
		ds = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_PROCESSORS_LIST);		
		for(int cpt = 1; cpt <= dynlen(ds); cpt++)
		{
			dyn_string temp;
			temp = sgDBGet(ds[cpt], DBKEY_CONNECTION_ID);			
			int i = temp[1];
			
			if(i == connectionId)
			{
				return ds[cpt];
			}
		}
		
		ds = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST);		
		for(int cpt = 1; cpt <= dynlen(ds); cpt++)
		{
			dyn_string temp;
			temp = sgDBGet(ds[cpt], DBKEY_CONNECTION_ID);			
			for(int cptConnection = 1; cptConnection <= dynlen(temp); cptConnection++)
			
			if(temp[cptConnection] == connectionId)
			{
				return ds[cpt];
			}
		}
		
		
		return "";
}
