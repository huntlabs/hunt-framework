/*
 * Copyright 2002-2016 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module hunt.framework.messaging.simp.stomp.StompCommand;

import hunt.framework.messaging.simp.SimpMessageType;
import hunt.util.traits;

import std.string;

/**
 * Represents a STOMP command.
 *
 * @author Rossen Stoyanchev
 * @author Juergen Hoeller
 * @since 4.0
 */
struct StompCommand {

	enum StompCommand Null = StompCommand("Null", SimpMessageType.OTHER);

	// client
	enum StompCommand STOMP = StompCommand("STOMP", SimpMessageType.CONNECT);
	enum StompCommand CONNECT = StompCommand("CONNECT", SimpMessageType.CONNECT);
	enum StompCommand DISCONNECT = StompCommand("DISCONNECT", SimpMessageType.DISCONNECT);
	enum StompCommand SUBSCRIBE = StompCommand("SUBSCRIBE", SimpMessageType.SUBSCRIBE, true, true, false);
	enum StompCommand UNSUBSCRIBE = StompCommand("UNSUBSCRIBE", SimpMessageType.UNSUBSCRIBE, false, true, false);
	enum StompCommand SEND = StompCommand("SEND", SimpMessageType.MESSAGE, true, false, true);
	enum StompCommand ACK = StompCommand("ACK", SimpMessageType.OTHER);
	enum StompCommand NACK = StompCommand("NACK", SimpMessageType.OTHER);
	enum StompCommand BEGIN = StompCommand("BEGIN", SimpMessageType.OTHER);
	enum StompCommand COMMIT = StompCommand("COMMIT", SimpMessageType.OTHER);
	enum StompCommand ABORT = StompCommand("ABORT", SimpMessageType.OTHER);

	// server
	enum StompCommand CONNECTED = StompCommand("CONNECTED", SimpMessageType.OTHER);
	enum StompCommand RECEIPT = StompCommand("RECEIPT", SimpMessageType.OTHER);
	enum StompCommand MESSAGE = StompCommand("MESSAGE", SimpMessageType.MESSAGE, true, true, true);
	enum StompCommand ERROR = StompCommand("ERROR", SimpMessageType.OTHER, false, false, true);

	mixin GetConstantValues!(StompCommand);

	private string _name;
	private SimpMessageType messageType;
	private bool destination;
	private bool subscriptionId;
	private bool hasBody;


	this(string name, SimpMessageType messageType) {
		this(name, messageType, false, false, false);
	}

	this(string name, SimpMessageType messageType, 
		bool destination, bool subscriptionId, bool hasBody) {
		this._name = toUpper(name);
		
		this.messageType = messageType;
		this.destination = destination;
		this.subscriptionId = subscriptionId;
		this.hasBody = hasBody;
	}

	static StompCommand valueOf(string name) {
		string n = toUpper(name);
		foreach(ref StompCommand s; values) {
			if(n == s._name) {
				return s;
			}
		}
		return Null;
	}

	string name() {
		return _name;
	}

	SimpMessageType getMessageType() {
		return this.messageType;
	}

	bool requiresDestination() {
		return this.destination;
	}

	bool requiresSubscriptionId() {
		return this.subscriptionId;
	}

	bool requiresContentLength() {
		return this.hasBody;
	}

	bool isBodyAllowed() {
		return this.hasBody;
	}

}
