/*
 * Copyright 2002-2017 the original author or authors.
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

module hunt.framework.messaging.simp.stomp.StompHeaderAccessor;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.simp.stomp.StompCommand;
import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
import hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.http.codec.http.model.MimeTypes;

import hunt.container;
import hunt.lang.Charset;
import hunt.lang.exception;
import hunt.lang.Integer;
import hunt.lang.Nullable;
import hunt.string;

import std.conv;


// import hunt.framework.util.ClassUtils;
// import hunt.framework.util.CollectionUtils;
import hunt.http.codec.http.model.MimeTypes;
// import hunt.framework.util.MimeTypeUtils;
// import hunt.framework.util.StringUtils;

alias Charset = string;

/**
 * A {@code MessageHeaderAccessor} to use when creating a {@code Message} from
 * a decoded STOMP frame, or when encoding a {@code Message} to a STOMP frame.
 *
 * <p>When created from STOMP frame content, the actual STOMP headers are
 * stored in the native header sub-map managed by the parent class
 * {@link hunt.framework.messaging.support.NativeMessageHeaderAccessor}
 * while the parent class {@link SimpMessageHeaderAccessor} manages common
 * processing headers some of which are based on STOMP headers
 * (e.g. destination, content-type, etc).
 *
 * <p>An instance of this class can also be created by wrapping an existing
 * {@code Message}. That message may have been created with the more generic
 * {@link hunt.framework.messaging.simp.SimpMessageHeaderAccessor} in
 * which case STOMP headers are created from common processing headers.
 * In this case it is also necessary to invoke either
 * {@link #updateStompCommandAsClientMessage()} or
 * {@link #updateStompCommandAsServerMessage()} if sending a message and
 * depending on whether a message is sent to a client or the message broker.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class StompHeaderAccessor : SimpMessageHeaderAccessor {

	private static shared(long) messageIdCounter = 0;

	private enum long[] DEFAULT_HEARTBEAT = [0, 0];


	// STOMP header names

	enum string STOMP_ID_HEADER = "id";

	enum string STOMP_HOST_HEADER = "host";

	enum string STOMP_ACCEPT_VERSION_HEADER = "accept-version";

	enum string STOMP_MESSAGE_ID_HEADER = "message-id";

	enum string STOMP_RECEIPT_HEADER = "receipt"; // any client frame except CONNECT

	enum string STOMP_RECEIPT_ID_HEADER = "receipt-id"; // RECEIPT frame

	enum string STOMP_SUBSCRIPTION_HEADER = "subscription";

	enum string STOMP_VERSION_HEADER = "version";

	enum string STOMP_MESSAGE_HEADER = "message";

	enum string STOMP_ACK_HEADER = "ack";

	enum string STOMP_NACK_HEADER = "nack";

	enum string STOMP_LOGIN_HEADER = "login";

	enum string STOMP_PASSCODE_HEADER = "passcode";

	enum string STOMP_DESTINATION_HEADER = "destination";

	enum string STOMP_CONTENT_TYPE_HEADER = "content-type";

	enum string STOMP_CONTENT_LENGTH_HEADER = "content-length";

	enum string STOMP_HEARTBEAT_HEADER = "heart-beat";

	// Other header names

	private enum string COMMAND_HEADER = "stompCommand";

	private enum string CREDENTIALS_HEADER = "stompCredentials";


	/**
	 * A constructor for creating message headers from a parsed STOMP frame.
	 */
	this(StompCommand command, Map!(string, List!(string)) externalSourceHeaders) {
		super(command.getMessageType(), externalSourceHeaders);
		setHeader(COMMAND_HEADER, command);
		updateSimpMessageHeadersFromStompHeaders();
	}

	/**
	 * A constructor for accessing and modifying existing message headers.
	 * Note that the message headers may not have been created from a STOMP frame
	 * but may have rather originated from using the more generic
	 * {@link hunt.framework.messaging.simp.SimpMessageHeaderAccessor}.
	 */
	this(MessageBase message) {
		super(message);
		updateStompHeadersFromSimpMessageHeaders();
	}

	this() {
		super(SimpMessageType.HEARTBEAT, null);
	}


	void updateSimpMessageHeadersFromStompHeaders() {
		if (getNativeHeaders() is null) {
			return;
		}
		string value = getFirstNativeHeader(STOMP_DESTINATION_HEADER);
		if (value !is null) {
			super.setDestination(value);
		}
		value = getFirstNativeHeader(STOMP_CONTENT_TYPE_HEADER);
		if (value !is null) {
			super.setContentType(MimeTypeUtils.parseMimeType(value));
		}
		Nullable!StompCommand command = getCommand();
		if (StompCommand.MESSAGE == command) {
			value = getFirstNativeHeader(STOMP_SUBSCRIPTION_HEADER);
			if (value !is null) {
				super.setSubscriptionId(value);
			}
		}
		else if (StompCommand.SUBSCRIBE == command || StompCommand.UNSUBSCRIBE == command) {
			value = getFirstNativeHeader(STOMP_ID_HEADER);
			if (value !is null) {
				super.setSubscriptionId(value);
			}
		}
		else if (StompCommand.CONNECT == command) {
			protectPasscode();
		}
	}

	void updateStompHeadersFromSimpMessageHeaders() {
		string destination = getDestination();
		if (destination !is null) {
			setNativeHeader(STOMP_DESTINATION_HEADER, destination);
		}
		MimeType contentType = getContentType();
		if (contentType !is null) {
			setNativeHeader(STOMP_CONTENT_TYPE_HEADER, contentType.toString());
		}
		trySetStompHeaderForSubscriptionId();
	}


	override
	protected MessageHeaderAccessor createAccessor(MessageBase message) {
		return wrap(message);
	}

	// Redeclared for visibility within simp.stomp
	override
	protected Map!(string, List!(string)) getNativeHeaders() {
		return super.getNativeHeaders();
	}

	StompCommand updateStompCommandAsClientMessage() {
		Nullable!SimpMessageType messageType = getMessageType();
		if (messageType != SimpMessageType.MESSAGE) {
			throw new IllegalStateException("Unexpected message type " ~ messageType.toString());
		}
		Nullable!StompCommand command = getCommand();
		if (command is null) {
			command = new Nullable!StompCommand(StompCommand.SEND);
			setHeader(COMMAND_HEADER, command);
		}
		else if (command != (StompCommand.SEND)) {
			throw new IllegalStateException("Unexpected STOMP command " ~ command.toString());
		}
		return command;
	}

	void updateStompCommandAsServerMessage() {
		Nullable!SimpMessageType messageType = getMessageType();
		if (messageType != SimpMessageType.MESSAGE) {
			throw new IllegalStateException("Unexpected message type " ~ messageType.toString());
		}
		Nullable!StompCommand command = getCommand();
		if ((command is null) || StompCommand.SEND == command) {
			setHeader(COMMAND_HEADER, StompCommand.MESSAGE);
		}
		else if (!StompCommand.MESSAGE == command) {
			throw new IllegalStateException("Unexpected STOMP command " ~ command);
		}
		trySetStompHeaderForSubscriptionId();
		if (getMessageId() is null) {
			string messageId = getSessionId() ~ "-" ~ messageIdCounter.getAndIncrement();
			setNativeHeader(STOMP_MESSAGE_ID_HEADER, messageId);
		}
	}

	/**
	 * Return the STOMP command, or {@code null} if not yet set.
	 */
	
	Nullable!StompCommand getCommand() {
		return cast(Nullable!StompCommand) getHeader(COMMAND_HEADER);
	}

	bool isHeartbeat() {
		return (SimpMessageType.HEARTBEAT == getMessageType());
	}

	long[] getHeartbeat() {
		string rawValue = getFirstNativeHeader(STOMP_HEARTBEAT_HEADER);
		string[] rawValues = StringUtils.split(rawValue, ",");
		if (rawValues is null) {
			return DEFAULT_HEARTBEAT.dup;
		}
		return [cast(long)rawValues[0], cast(long)rawValues[1]];
	}

	void setAcceptVersion(string acceptVersion) {
		setNativeHeader(STOMP_ACCEPT_VERSION_HEADER, acceptVersion);
	}

	Set!(string) getAcceptVersion() {
		string rawValue = getFirstNativeHeader(STOMP_ACCEPT_VERSION_HEADER);
		return (rawValue !is null ? StringUtils.commaDelimitedListToSet(rawValue) : Collections.emptySet());
	}

	void setHost(string host) {
		setNativeHeader(STOMP_HOST_HEADER, host);
	}

	
	string getHost() {
		return getFirstNativeHeader(STOMP_HOST_HEADER);
	}

	override
	void setDestination(string destination) {
		super.setDestination(destination);
		setNativeHeader(STOMP_DESTINATION_HEADER, destination);
	}

	override
	void setContentType(MimeType contentType) {
		super.setContentType(contentType);
		setNativeHeader(STOMP_CONTENT_TYPE_HEADER, contentType.toString());
	}

	override
	void setSubscriptionId(string subscriptionId) {
		super.setSubscriptionId(subscriptionId);
		trySetStompHeaderForSubscriptionId();
	}

	private void trySetStompHeaderForSubscriptionId() {
		string subscriptionId = getSubscriptionId();
		if (subscriptionId !is null) {
			Nullable!StompCommand command = getCommand();
			if (command !is null && StompCommand.MESSAGE == command) {
				setNativeHeader(STOMP_SUBSCRIPTION_HEADER, subscriptionId);
			}
			else {
				SimpMessageType messageType = getMessageType();
				if (SimpMessageType.SUBSCRIBE == messageType || SimpMessageType.UNSUBSCRIBE == messageType) {
					setNativeHeader(STOMP_ID_HEADER, subscriptionId);
				}
			}
		}
	}

	
	Integer getContentLength() {
		string header = getFirstNativeHeader(STOMP_CONTENT_LENGTH_HEADER);
		return (header !is null ? Integer.valueOf(header) : null);
	}

	void setContentLength(int contentLength) {
		setNativeHeader(STOMP_CONTENT_LENGTH_HEADER, string.valueOf(contentLength));
	}

	void setHeartbeat(long cx, long cy) {
		setNativeHeader(STOMP_HEARTBEAT_HEADER, cx ~ "," ~ cy);
	}

	void setAck(string ack) {
		setNativeHeader(STOMP_ACK_HEADER, ack);
	}

	
	string getAck() {
		return getFirstNativeHeader(STOMP_ACK_HEADER);
	}

	void setNack(string nack) {
		setNativeHeader(STOMP_NACK_HEADER, nack);
	}

	
	string getNack() {
		return getFirstNativeHeader(STOMP_NACK_HEADER);
	}

	void setLogin(string login) {
		setNativeHeader(STOMP_LOGIN_HEADER, login);
	}

	
	string getLogin() {
		return getFirstNativeHeader(STOMP_LOGIN_HEADER);
	}

	void setPasscode(string passcode) {
		setNativeHeader(STOMP_PASSCODE_HEADER, passcode);
		protectPasscode();
	}

	private void protectPasscode() {
		string value = getFirstNativeHeader(STOMP_PASSCODE_HEADER);
		if (value !is null && !"PROTECTED" == value) {
			setHeader(CREDENTIALS_HEADER, new StompPasscode(value));
			setNativeHeader(STOMP_PASSCODE_HEADER, "PROTECTED");
		}
	}

	/**
	 * Return the passcode header value, or {@code null} if not set.
	 */
	
	string getPasscode() {
		StompPasscode credentials = cast(StompPasscode) getHeader(CREDENTIALS_HEADER);
		return (credentials !is null ? credentials.passcode : null);
	}

	void setReceiptId(string receiptId) {
		setNativeHeader(STOMP_RECEIPT_ID_HEADER, receiptId);
	}

	
	string getReceiptId() {
		return getFirstNativeHeader(STOMP_RECEIPT_ID_HEADER);
	}

	void setReceipt(string receiptId) {
		setNativeHeader(STOMP_RECEIPT_HEADER, receiptId);
	}

	
	string getReceipt() {
		return getFirstNativeHeader(STOMP_RECEIPT_HEADER);
	}

	
	string getMessage() {
		return getFirstNativeHeader(STOMP_MESSAGE_HEADER);
	}

	void setMessage(string content) {
		setNativeHeader(STOMP_MESSAGE_HEADER, content);
	}

	
	string getMessageId() {
		return getFirstNativeHeader(STOMP_MESSAGE_ID_HEADER);
	}

	void setMessageId(string id) {
		setNativeHeader(STOMP_MESSAGE_ID_HEADER, id);
	}

	
	string getVersion() {
		return getFirstNativeHeader(STOMP_VERSION_HEADER);
	}

	void setVersion(string ver) {
		setNativeHeader(STOMP_VERSION_HEADER, ver);
	}


	// Logging related

	override
	string getShortLogMessage(Object payload) {
		Nullable!StompCommand command = getCommand();
		if (StompCommand.SUBSCRIBE == command) {
			return "SUBSCRIBE " ~ getDestination() ~ " id=" ~ getSubscriptionId() ~ appendSession();
		}
		else if (StompCommand.UNSUBSCRIBE == command) {
			return "UNSUBSCRIBE id=" ~ getSubscriptionId() ~ appendSession();
		}
		else if (StompCommand.SEND == command) {
			return "SEND " ~ getDestination() ~ appendSession() ~ appendPayload(payload);
		}
		else if (StompCommand.CONNECT == command) {
			// Principal user = getUser();
			// return "CONNECT" ~ (user !is null ? " user=" ~ user.getName() : "") ~ appendSession();
			return "CONNECT" ~ appendSession();
		}
		else if (StompCommand.CONNECTED == command) {
			return "CONNECTED heart-beat=" ~ Arrays.toString(getHeartbeat()) ~ appendSession();
		}
		else if (StompCommand.DISCONNECT == command) {
			string receipt = getReceipt();
			return "DISCONNECT" ~ (receipt !is null ? " receipt=" ~ receipt : "") ~ appendSession();
		}
		else {
			return getDetailedLogMessage(payload);
		}
	}

	override
	string getDetailedLogMessage(Object payload) {
		if (isHeartbeat()) {
			string sessionId = getSessionId();
			return "heart-beat" ~ (sessionId !is null ? " in session " ~ sessionId : "");
		}
		Nullable!StompCommand command = getCommand();
		if (command is null) {
			return super.getDetailedLogMessage(payload);
		}
		StringBuilder sb = new StringBuilder();
		sb.append(command.name()).append(" ");
		Map!(string, List!(string)) nativeHeaders = getNativeHeaders();
		if (nativeHeaders !is null) {
			sb.append(nativeHeaders.toString());
		}
		sb.append(appendSession());
		// if (getUser() !is null) {
		// 	sb.append(", user=").append(getUser().getName());
		// }
		if (payload !is null && command.isBodyAllowed()) {
			sb.append(appendPayload(payload));
		}
		return sb.toString();
	}

	private string appendSession() {
		return " session=" ~ getSessionId();
	}

	private string appendPayload(Object payload) {
		Nullable!(byte[]) _payload = cast(Nullable!(byte[])) payload;
		if (_payload is null) {
			throw new IllegalStateException(
					"Expected byte array payload but got: " ~ typeid(payload).name);
		}
		byte[] bytes = _payload.value;
		MimeType mimeType = getContentType();
		string contentType = (mimeType !is null ? " " ~ mimeType.toString() : "");
		if (bytes.length == 0 || mimeType is null || !isReadableContentType()) {
			return contentType;
		}
		Charset charset = mimeType.getCharset();
		charset = (charset !is null ? charset : StandardCharsets.UTF_8);
		return (bytes.length < 80) ?
				contentType ~ " payload=" ~ new string(bytes, charset) :
				contentType ~ " payload=" ~ new string(Arrays.copyOf(bytes, 80), charset) ~ "...(truncated)";
	}


	// Static factory methods and accessors

	/**
	 * Create an instance for the given STOMP command.
	 */
	static StompHeaderAccessor create(StompCommand command) {
		return new StompHeaderAccessor(command, null);
	}

	/**
	 * Create an instance for the given STOMP command and headers.
	 */
	static StompHeaderAccessor create(StompCommand command, Map!(string, List!(string)) headers) {
		return new StompHeaderAccessor(command, headers);
	}

	/**
	 * Create headers for a heartbeat. While a STOMP heartbeat frame does not
	 * have headers, a session id is needed for processing purposes at a minimum.
	 */
	static StompHeaderAccessor createForHeartbeat() {
		return new StompHeaderAccessor();
	}

	/**
	 * Create an instance from the payload and headers of the given Message.
	 */
	static StompHeaderAccessor wrap(MessageBase message) {
		return new StompHeaderAccessor(message);
	}

	/**
	 * Return the STOMP command from the given headers, or {@code null} if not set.
	 */
	
	static Nullable!StompCommand getCommand(Map!(string, Object) headers) {
		return cast(Nullable!StompCommand) headers.get(COMMAND_HEADER);
	}

	/**
	 * Return the passcode header value, or {@code null} if not set.
	 */
	
	static string getPasscode(Map!(string, Object) headers) {
		StompPasscode credentials = cast(StompPasscode) headers.get(CREDENTIALS_HEADER);
		return (credentials !is null ? credentials.passcode : null);
	}

	
	static int getContentLength(Map!(string, List!(string)) nativeHeaders) {
		List!(string) values = nativeHeaders.get(STOMP_CONTENT_LENGTH_HEADER);
		return (!CollectionUtils.isEmpty(values) ? to!int(values.get(0)) : null);
	}

}


private class StompPasscode {

	private string passcode;

	this(string passcode) {
		this.passcode = passcode;
	}

	override
	string toString() {
		return "[PROTECTED]";
	}
}