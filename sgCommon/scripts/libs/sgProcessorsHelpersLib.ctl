const string DBKEY_TRANS_BUFFER = "TransactionsBuffer";
const string DBKEY_PROCESSOR_PREFIX = "PROCESSOR_";

const string DBKEY_PROC_STATUS = "Status";
const string DBKEY_SOCKETS_PREFIX = "Socket ";
const string DBKEY_MESSAGES_IN = "Messages in";
const string DBKEY_MESSAGES_OUT = "Messages out";
const string DBKEY_CONNECTION_ID = "Connection id";
const string DBKEY_PROCESSORS_LIST = "All processors";
const string DBKEY_IS_XML = "Is XML";
const string DBKEY_SERVERS_LIST = "All servers";
const string DBKEY_SERVER_PORT = "Server port";
const string DBKEY_SERVER_TIMEOUT = "Server timeout";
const string DBKEY_SERVER_DELIMITER = "Server delimiter";
const string DBKEY_CONNECTIONS_TO_CLOSE = "Connections to close";
const string DBKEY_CONNECTIONS_TRIALS = "Connections trials";
const string DBKEY_NEXT_SOCKET = "Next socket";

// 20070111 aj don't try to (re)connect immediately
const string DBKEY_RECONNECTION_CNT = "Reconnection Delay Counter";

// XML fields  
const string PORT_TAG = "Port";
const string IS_XML_TAG = "IsXML";
const string TIMEOUT_TAG = "TimeOut";
const string STATUS_TAG = "Status";
const string MESSAGE_TAG = "MessageFromSystem";
const string CONNECTION_ID_TAG = "ConnectionId";
const string IP_ADDRESS_TAG = "IPAddress";

// XML headers
const string LISTEN_TAG            = "Listen";

const string DELIMITER_TAG				 = "Delimiter";
const string LISTEN_ACK_TAG        = "ListenAcknowledge";
const string MESSAGE_RECEIVED_TAG  = "MessageReceived";
const string SEND_MESSAGE_TAG      = "SendMessage";
const string MESSAGE_ACK_TAG  		 = "MessageAcknowledge";
const string CLOSE_CONNECTION_TAG  = "CloseConnection";
const string CONNECTION_CLOSED_TAG = "ConnectionClosed"; // client loss or close connection

const string CONNECT_TAG					 = "Connect";
const string CONNECT_ACK_TAG			 = "ConnectAcknowledge";
const string KILL_MANAGER_TAG			 = "KillManager";

const string HEARTBEAT_TAG				 = "Heartbeat";

const string TRANSACTION_ID 					= "TransactionId";

const int PROC_STATUS_CLOSED = 0;
const int PROC_STATUS_READY = 1;
const int PROC_STATUS_OPEN = 2;

bool sgProcessorsLibInit()
{
	sgDBWaitForInit();

	dyn_string empty;
	
	bool b;
	b = sgDBCreateTable(DBKEY_TRANS_BUFFER);
	if(!b)
		return false;

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_PROCESSORS_LIST, empty);
	if(!b)
		return false;

	b = sgDBSet(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST, empty);
	if(!b)
		return false;
		
	return true;
}

int sgProcessorsGetNextSocket(string processorName)
{
	string tableName;
	
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;
	
	dyn_string ds;
	
	ds = sgDBGet(tableName, DBKEY_NEXT_SOCKET);
	
	return ds[1];
}

int sgProcessorsGetStatus(string processorName)
{
	string tableName;
	
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;
	
	dyn_string ds;
	
	ds = sgDBGet(tableName, DBKEY_PROC_STATUS);
	int res;
	res = ds[1];

	if(res == PROC_STATUS_READY)
	{
		sgDBSet(tableName, DBKEY_PROC_STATUS, PROC_STATUS_OPEN);
	}
	
	return ds[1];

}

int sgProcessorsGetConnectionsTrials(string processorName)
{
	string tableName;
	
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;
	
	dyn_string ds;
	
	ds = sgDBGet(tableName, DBKEY_CONNECTIONS_TRIALS);
	
	return ds[1];
}


dyn_string sgProcessorsGetMessages(string processorName)
{
	string tableName;
	
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;
	
	dyn_string ds;
	dyn_string empty;
	
	ds = sgDBGet(tableName, DBKEY_MESSAGES_IN);
	sgDBSet(tableName, DBKEY_MESSAGES_IN, empty);
	
	return ds;
}

bool sgProcessorsSendMessage(string processorName, string message)
{
	string tableName;
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;

	// don't use sgProcessorsGetStatus, otherwise it could turn the processor from READY to OPEN
	string status;
	status = sgDBGet(tableName, DBKEY_PROC_STATUS);
	
	if(status != PROC_STATUS_OPEN)
	{
		// DebugTN("sgProcessorsHelpersLib.sgProcessorsSendMessage: processor " + processorName + " is not open");
		return false;
	}
	
	
	bool b;
	
	b = sgDBAppend(tableName, DBKEY_MESSAGES_OUT, message);
	
	return b;
	
}

bool sgProcessorsServerSendMessage(string processorName, int connectionId, string message)
{
	string tableName;
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;

	// don't use sgProcessorsGetStatus, otherwise it could turn the processor from READY to OPEN
	string status;
	status = sgDBGet(tableName, DBKEY_PROC_STATUS);
	
	if(status != PROC_STATUS_OPEN)
	{
		// DebugTN("sgProcessorsHelpersLib.sgProcessorsServerSendMessage: processor " + processorName + " is not open");
		return false;
	}

	dyn_string currentConnections;
	
	currentConnections = sgDBGet(tableName, DBKEY_CONNECTION_ID);
	if(!dynContains(currentConnections, connectionId))
	{
		// DebugTN("sgProcessorsHelpersLib.sgProcessorsServerSendMessage: processor " + processorName + ", connection " + connectionId + " is not open");
		return false;
	}
	
	bool b;
	
	b = sgDBAppend(tableName, DBKEY_MESSAGES_OUT, connectionId);
	b = sgDBAppend(tableName, DBKEY_MESSAGES_OUT, message);
	
	return b;
	
}

bool sgProcessorsCloseConnection(string processorName, int connectionId)
{
	string tableName;
	tableName = DBKEY_PROCESSOR_PREFIX + processorName;
	
	bool b;
	
	b = sgDBAppend(tableName, DBKEY_CONNECTIONS_TO_CLOSE, connectionId);
	
	return b;
}

void sgProcessorsCloseAll()
{
	// CLIENT PROCESSORS
	dyn_string processors;
	dyn_string empty;
	
	processors = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_PROCESSORS_LIST);
	
//	DebugTN("Processors list: " + processors);
	
	for(int cpt = 1; cpt <= dynlen(processors); cpt++)
	{
		sgDBSet(processors[cpt], DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
		sgDBSet(processors[cpt], DBKEY_MESSAGES_IN, empty);
		sgDBSet(processors[cpt], DBKEY_MESSAGES_OUT, empty);
		sgDBSet(processors[cpt], DBKEY_CONNECTION_ID, -1);
		sgDBSet(processors[cpt], DBKEY_CONNECTIONS_TRIALS, 0);

	}

	// SERVER PROCESSORS	
	processors = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST);
	for(int cpt = 1; cpt <= dynlen(processors); cpt++)
	{
		sgDBSet(processors[cpt], DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
		sgDBSet(processors[cpt], DBKEY_MESSAGES_IN, empty);
		sgDBSet(processors[cpt], DBKEY_MESSAGES_OUT, empty);
		sgDBSet(processors[cpt], DBKEY_CONNECTION_ID, empty);
		sgDBSet(processors[cpt], DBKEY_CONNECTIONS_TO_CLOSE, empty);
	}
	
	// CLEAR TRANSACTIONS BUFFER
	dyn_string transactions;
	
	transactions = sgDBTableKeys(DBKEY_TRANS_BUFFER);
	for(int cpt = 1; cpt <= dynlen(transactions); cpt++)
	{
		sgDBRemove(DBKEY_TRANS_BUFFER, transactions[cpt]);
	}
	
}

void buildTransactions()
{
	// CLIENT PROCESSORS
	dyn_string processors;
	
	processors = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_PROCESSORS_LIST);
	
//	DebugTN("Processors list: " + processors);
	
	for(int cpt = 1; cpt <= dynlen(processors); cpt++)
	{
		string status;
		status = sgDBGet(processors[cpt], DBKEY_PROC_STATUS);
		if(status == PROC_STATUS_CLOSED)
		{

			// 20070111 aj don't try to (re)connect immediately
			dyn_string tmp = sgDBGet(processors[cpt], DBKEY_RECONNECTION_CNT);
			//DebugTN(tmp);
			int cnt = tmp[1];
			cnt++;
			if (cnt <= (4 + (dynlen(processors) * 4)) )
				sgDBSet(processors[cpt], DBKEY_RECONNECTION_CNT, makeDynString(cnt));
			else
				sgDBSet(processors[cpt], DBKEY_RECONNECTION_CNT, makeDynString(0));
			
			if (cnt == (4 + (cpt*4)) )
			{
			// 20070111 aj end
			
				string ip;
				string port;
				string delim;
				string timeOut;
				dyn_string params;
				bool isXML;
				
				int nextSocket;
				
				params = sgDBGet(processors[cpt], DBKEY_NEXT_SOCKET);
				nextSocket = params[1];
				
				params = sgDBGet(processors[cpt], DBKEY_SOCKETS_PREFIX + nextSocket);
				ip = params[1];
				port = params[2];
				timeOut = params[3];
				delim = params[4];
	
				// increment socket number for next trial
				nextSocket++;
				
				// check that next socket exists
				string testSocketName;
				testSocketName = DBKEY_SOCKETS_PREFIX + nextSocket;
				params = sgDBTableKeys(processors[cpt]);
				if(!dynContains(params, testSocketName))
				{
					nextSocket = 1;
				}	
				sgDBSet(processors[cpt], DBKEY_NEXT_SOCKET, nextSocket);
	
				
				params = sgDBGet(processors[cpt], DBKEY_IS_XML);
				isXML = params[1];
				
				string xmlMessage, xmlPort, xmlIPAddress, xmlTimeout, xmlDelimiter, xmlIsXML;
				dyn_string empty;
				
				xmlPort      = XMLcreateTag(PORT_TAG, empty, empty, port);
				xmlIPAddress = XMLcreateTag(IP_ADDRESS_TAG, empty, empty, ip);
				xmlTimeout   = XMLcreateTag(TIMEOUT_TAG, empty, empty, timeOut);
				xmlIsXML     = XMLcreateTag(IS_XML_TAG, empty, empty, isXML);
				xmlDelimiter = XMLcreateTag(DELIMITER_TAG, empty, empty, delim);
				
				xmlMessage = xmlPort + xmlIPAddress + xmlTimeout + xmlIsXML + xmlDelimiter;
				
				int transactionId = getTransactionId();	
				xmlMessage = XMLcreateTag(CONNECT_TAG, makeDynString(TRANSACTION_ID), makeDynString(transactionId), xmlMessage);
			
				xmlMessage = XMLaddHeader(xmlMessage);
				
				int trials;
				params = sgDBGet(processors[cpt], DBKEY_CONNECTIONS_TRIALS);
				
				trials = params[1];
				
				sgDBSet(processors[cpt], DBKEY_CONNECTIONS_TRIALS, trials + 1);
				
				sgProcessorAppendTransaction(processors[cpt], transactionId, -1, xmlMessage, true);
			
			// create connection XML
			}
		}
		else
		{
			dyn_string messagesOut;
			int connectionId;
			dyn_string empty;
			dyn_string temp;
			temp = sgDBGet(processors[cpt], DBKEY_CONNECTION_ID);
			connectionId = temp[1];
			messagesOut = sgDBGet(processors[cpt], DBKEY_MESSAGES_OUT);
			sgDBSet(processors[cpt], DBKEY_MESSAGES_OUT, empty);
			
			for(int cptMessages = 1; cptMessages <= dynlen(messagesOut); cptMessages++)
			{
				string message;
				message = messagesOut[cptMessages];
				
				bool isXML;
				dyn_string ds;
				
				ds = sgDBGet(processors[cpt], DBKEY_IS_XML);
				isXML = ds[1];
				
				// create send message XML
				string xmlConnectionId, xmlMessageToSend, xmlMessage;
				int transactionId = getTransactionId();
				xmlConnectionId  = XMLcreateTag(CONNECTION_ID_TAG, empty, empty, connectionId);
				xmlMessageToSend = XMLcreateTag(MESSAGE_TAG, empty, empty, message);
			  xmlMessage = xmlConnectionId + xmlMessageToSend;
			  	
				xmlMessage = XMLcreateTag(SEND_MESSAGE_TAG,  makeDynString(TRANSACTION_ID), makeDynString(transactionId), xmlMessage);
				xmlMessage = XMLaddHeader(xmlMessage);
				sgProcessorAppendTransaction(processors[cpt], transactionId, connectionId, xmlMessage, true);
			}
		}
	}
	
	// SERVER PROCESSORS
	processors = sgDBGet(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST);
	for(int cpt = 1; cpt <= dynlen(processors); cpt++)
	{
		string status;
		status = sgDBGet(processors[cpt], DBKEY_PROC_STATUS);
		if(status == PROC_STATUS_CLOSED)
		{
		
			string port;
			string delim;
			string timeOut;
			bool isXML;
			dyn_string params;
			
			

			params = sgDBGet(processors[cpt], DBKEY_SERVER_PORT);
			port = params[1];

			params = sgDBGet(processors[cpt], DBKEY_SERVER_DELIMITER);
			delim = params[1];

			params = sgDBGet(processors[cpt], DBKEY_SERVER_TIMEOUT);
			timeOut = params[1];

			params = sgDBGet(processors[cpt], DBKEY_IS_XML);
			isXML = params[1];
			
			string xmlPort, xmlTimeOut, xmlDelimiter, xmlType, xmlMessage;
			dyn_string empty;
							
			xmlPort = XMLcreateTag(PORT_TAG, empty, empty, port);
			
			xmlTimeOut = XMLcreateTag(TIMEOUT_TAG, empty, empty, timeOut);
			
			xmlDelimiter = XMLcreateTag(DELIMITER_TAG, empty, empty, delim);
			
			xmlType = XMLcreateTag(IS_XML_TAG, empty, empty, isXML);
			
		  xmlMessage = xmlPort + xmlTimeOut + xmlDelimiter + xmlType;
		
			int transactionId;
			transactionId = getTransactionId();
			
			xmlMessage = XMLcreateTag(LISTEN_TAG, makeDynString(TRANSACTION_ID), makeDynString(transactionId), xmlMessage);
		
			xmlMessage = XMLaddHeader(xmlMessage);			
			
			sgProcessorAppendTransaction(processors[cpt], transactionId, -1, xmlMessage, true);
			
			// create connection XML
		}
		else // send messages
		{
			dyn_string messagesOut;
			dyn_string empty;
			dyn_string temp;
			messagesOut = sgDBGet(processors[cpt], DBKEY_MESSAGES_OUT);
			sgDBSet(processors[cpt], DBKEY_MESSAGES_OUT, empty);
			
			dyn_string currentConnections;
			currentConnections = sgDBGet(processors[cpt], DBKEY_CONNECTION_ID);
			
			for(int cptMessages = 1; cptMessages <= dynlen(messagesOut); cptMessages += 2)
			{
				string message;
				int connectionId;
				
				connectionId = messagesOut[cptMessages];
			
				if(dynContains(currentConnections, connectionId))
				{
				
					message = messagesOut[cptMessages + 1];
					
					
					// check that connection id is still valid
					
					
					
				//	 create send message XML
					string xmlConnectionId, xmlMessageToSend, xmlMessage;
					int transactionId = getTransactionId();
					xmlConnectionId  = XMLcreateTag(CONNECTION_ID_TAG, empty, empty, connectionId);
					xmlMessageToSend = XMLcreateTag(MESSAGE_TAG, empty, empty, message);
				  xmlMessage = xmlConnectionId + xmlMessageToSend;
				  	
					xmlMessage = XMLcreateTag(SEND_MESSAGE_TAG,  makeDynString(TRANSACTION_ID), makeDynString(transactionId), xmlMessage);
					xmlMessage = XMLaddHeader(xmlMessage);
					sgProcessorAppendTransaction(processors[cpt], transactionId, connectionId, xmlMessage, true);
				}
			}				


			// close connections
			dyn_string connectionsToClose;
			connectionsToClose = sgDBGet(processors[cpt], DBKEY_CONNECTIONS_TO_CLOSE);
			sgDBSet(processors[cpt], DBKEY_CONNECTIONS_TO_CLOSE, empty);
			
			for(int connectionsCpt = 1; connectionsCpt <= dynlen(connectionsToClose); connectionsCpt++)
			{
					int connectionId = connectionsToClose[connectionsCpt];
			
					string xmlConnectionId, xmlMessage;
					dyn_string empty, ds;
					int transactionId = getTransactionId();
					xmlConnectionId = XMLcreateTag(CONNECTION_ID_TAG, empty, empty, connectionId);
					xmlMessage = XMLcreateTag(CLOSE_CONNECTION_TAG, makeDynString(TRANSACTION_ID), makeDynString(transactionId), xmlConnectionId);
					
					xmlMessage = XMLaddHeader(xmlMessage);
					
					sgProcessorAppendTransaction(processors[cpt], transactionId, connectionId, xmlMessage, false);
			}									
		}
	}

}

void sgProcessorAppendTransaction(string processorName, int transactionId, int connectionId, string transaction, bool needAck)
{
	sgDBSet(DBKEY_TRANS_BUFFER, transactionId, transaction);
	sgDBAppend(DBKEY_TRANS_BUFFER, transactionId, processorName);
	sgDBAppend(DBKEY_TRANS_BUFFER, transactionId, needAck);
	sgDBAppend(DBKEY_TRANS_BUFFER, transactionId, connectionId);
}

int gNextTransactionId = 0;
int getTransactionId()
{
	int res = gNextTransactionId;
	gNextTransactionId++;
	return res;	
}

bool sgProcessorCreate(string name, dyn_string ip, dyn_int port, int timeOut, string delimiter, bool isXML)
{
	dyn_string empty;
	bool b;
	string tableName = DBKEY_PROCESSOR_PREFIX + name;
	
	if(dynlen(ip) != dynlen(port))
	{
		DebugTN("sgProcessorCreate: ips and ports lists don't have the same size for processor " + name);
		return false;
		
	}
	
	b = sgDBCreateTable(tableName);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
	if(!b)
		return false;
	
	for(int cpt = 1; cpt <= dynlen(ip); cpt++)
	{
	
		b = sgDBSet(tableName, DBKEY_SOCKETS_PREFIX + cpt, ip[cpt]);
		if(!b)
			return false;
		
		b = sgDBAppend(tableName, DBKEY_SOCKETS_PREFIX + cpt, port[cpt]);
		if(!b)
			return false;
	
		b = sgDBAppend(tableName, DBKEY_SOCKETS_PREFIX + cpt, timeOut);
		if(!b)
			return false;
	
		b = sgDBAppend(tableName, DBKEY_SOCKETS_PREFIX + cpt, delimiter);
		if(!b)
			return false;
	}

	b = sgDBSet(tableName, DBKEY_NEXT_SOCKET, 1);
	if(!b)
		return false;	
	
	b = sgDBSet(tableName, DBKEY_MESSAGES_IN, empty);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_MESSAGES_OUT, empty);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_CONNECTION_ID, -1);
	if(!b)
		return false;

	b = sgDBSet(tableName, DBKEY_IS_XML, isXML);
	if(!b)
		return false;

	b = sgDBSet(tableName, DBKEY_CONNECTIONS_TRIALS, 0);
	if(!b)
		return false;

	// 20070111 aj don't try to (re)connect immediately
	b = sgDBSet(tableName, DBKEY_RECONNECTION_CNT, makeDynString(0));
	if(!b)
		return false;
		
	b = sgDBAppend(GLOBAL_TABLE_NAME, DBKEY_PROCESSORS_LIST, tableName);
	if(!b)
		return false;
		
		
	return true;
}

bool sgProcessorServerCreate(string name, int port, int timeOut, string delimiter, bool isXML)
{
	dyn_string empty;
	bool b;
	string tableName = DBKEY_PROCESSOR_PREFIX + name;
	
	b = sgDBCreateTable(tableName);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_PROC_STATUS, PROC_STATUS_CLOSED);
	if(!b)
		return false;
	
	b = sgDBSet(tableName, DBKEY_SERVER_PORT, port);
	if(!b)
		return false;

	b = sgDBSet(tableName, DBKEY_SERVER_TIMEOUT, timeOut);
	if(!b)
		return false;

	b = sgDBSet(tableName, DBKEY_SERVER_DELIMITER, delimiter);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_MESSAGES_IN, empty);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_MESSAGES_OUT, empty);
	if(!b)
		return false;
		
	b = sgDBSet(tableName, DBKEY_CONNECTION_ID, empty);
	if(!b)
		return false;

	b = sgDBSet(tableName, DBKEY_CONNECTIONS_TO_CLOSE, empty);
	if(!b)
		return false;

	b = sgDBSet(tableName, DBKEY_IS_XML, isXML);
	if(!b)
		return false;

		
	b = sgDBAppend(GLOBAL_TABLE_NAME, DBKEY_SERVERS_LIST, tableName);
	if(!b)
		return false;
		
		
	return true;
}

// 200911xx aj/pw new function to reset socket after (restart at the default socket after a switchover)
bool sgProcessorResetNextSocket(string processorName)
{
  string tableName;
  bool b;
	
  tableName = DBKEY_PROCESSOR_PREFIX + processorName;
  b = sgDBSet(tableName, DBKEY_NEXT_SOCKET, 1);
  if(!b)
    return false;

  return true;	
}

