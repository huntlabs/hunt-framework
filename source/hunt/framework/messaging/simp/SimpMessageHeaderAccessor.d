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

module hunt.framework.messaging.simp.SimpMessageHeaderAccessor;

// import java.security.Principal;
import hunt.container.List;
import hunt.container.Map;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.support.IdTimestampMessageHeaderInitializer;
import hunt.framework.messaging.support.MessageHeaderAccessor;
import hunt.framework.messaging.support.NativeMessageHeaderAccessor;

/**
 * A base class for working with message headers in simple messaging protocols that
 * support basic messaging patterns. Provides uniform access to specific values common
 * across protocols such as a destination, message type (e.g. publish, subscribe, etc),
 * session id, and others.
 *
 * <p>Use one of the static factory method in this class, then call getters and setters,
 * and at the end if necessary call {@link #toMap()} to obtain the updated headers.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class SimpMessageHeaderAccessor : NativeMessageHeaderAccessor {

	private __gshared IdTimestampMessageHeaderInitializer headerInitializer;

	shared static this() {
		headerInitializer = new IdTimestampMessageHeaderInitializer();
		headerInitializer.setDisableIdGeneration();
		headerInitializer.setEnableTimestamp(false);
	}

	// SiMP header names

	enum string DESTINATION_HEADER = "simpDestination";

	enum string MESSAGE_TYPE_HEADER = "simpMessageType";

	enum string SESSION_ID_HEADER = "simpSessionId";

	enum string SESSION_ATTRIBUTES = "simpSessionAttributes";

	enum string SUBSCRIPTION_ID_HEADER = "simpSubscriptionId";

	enum string USER_HEADER = "simpUser";

	enum string CONNECT_MESSAGE_HEADER = "simpConnectMessage";

	enum string DISCONNECT_MESSAGE_HEADER = "simpDisconnectMessage";

	enum string HEART_BEAT_HEADER = "simpHeartbeat";


	/**
	 * A header for internal use with "user" destinations where we need to
	 * restore the destination prior to sending messages to clients.
	 */
	enum string ORIGINAL_DESTINATION = "simpOrigDestination";

	/**
	 * A header that indicates to the broker that the sender will ignore errors.
	 * The header is simply checked for presence or absence.
	 */
	enum string IGNORE_ERROR = "simpIgnoreError";


	// /**
	//  * A constructor for creating new message headers.
	//  * This constructor is protected. See factory methods in this and sub-classes.
	//  */
	// protected this(SimpMessageType messageType,
	// 		Map!(string, List!string) externalSourceHeaders) {

	// 	super(externalSourceHeaders);
	// 	assert(messageType, "MessageType must not be null");
	// 	setHeader(MESSAGE_TYPE_HEADER, messageType);
	// 	headerInitializer.initHeaders(this);
	// }

	// /**
	//  * A constructor for accessing and modifying existing message headers. This
	//  * constructor is protected. See factory methods in this and sub-classes.
	//  */
	// protected this(Message<?> message) {
	// 	super(message);
	// 	headerInitializer.initHeaders(this);
	// }


	// override
	// protected MessageHeaderAccessor createAccessor(Message<?> message) {
	// 	return wrap(message);
	// }

	// void setMessageTypeIfNotSet(SimpMessageType messageType) {
	// 	if (getMessageType() is null) {
	// 		setHeader(MESSAGE_TYPE_HEADER, messageType);
	// 	}
	// }

	
	// SimpMessageType getMessageType() {
	// 	return cast(SimpMessageType) getHeader(MESSAGE_TYPE_HEADER);
	// }

	// void setDestination(string destination) {
	// 	setHeader(DESTINATION_HEADER, destination);
	// }

	
	// string getDestination() {
	// 	return cast(string) getHeader(DESTINATION_HEADER);
	// }

	// void setSubscriptionId(string subscriptionId) {
	// 	setHeader(SUBSCRIPTION_ID_HEADER, subscriptionId);
	// }

	
	// string getSubscriptionId() {
	// 	return cast(string) getHeader(SUBSCRIPTION_ID_HEADER);
	// }

	// void setSessionId(string sessionId) {
	// 	setHeader(SESSION_ID_HEADER, sessionId);
	// }

	// /**
	//  * Return the id of the current session.
	//  */
	
	// string getSessionId() {
	// 	return cast(string) getHeader(SESSION_ID_HEADER);
	// }

	// /**
	//  * A static alternative for access to the session attributes header.
	//  */
	// void setSessionAttributes(Map!(string, Object) attributes) {
	// 	setHeader(SESSION_ATTRIBUTES, attributes);
	// }

	// /**
	//  * Return the attributes associated with the current session.
	//  */
	
	
	// Map!(string, Object) getSessionAttributes() {
	// 	return (Map!(string, Object)) getHeader(SESSION_ATTRIBUTES);
	// }

	// void setUser(Principal principal) {
	// 	setHeader(USER_HEADER, principal);
	// }

	// /**
	//  * Return the user associated with the current session.
	//  */
	
	// Principal getUser() {
	// 	return (Principal) getHeader(USER_HEADER);
	// }

	// override
	// string getShortLogMessage(Object payload) {
	// 	if (getMessageType() is null) {
	// 		return super.getDetailedLogMessage(payload);
	// 	}
	// 	StringBuilder sb = getBaseLogMessage();
	// 	if (!CollectionUtils.isEmpty(getSessionAttributes())) {
	// 		sb.append(" attributes[").append(getSessionAttributes().size()).append("]");
	// 	}
	// 	sb.append(getShortPayloadLogMessage(payload));
	// 	return sb.toString();
	// }

	
	// override
	// string getDetailedLogMessage(Object payload) {
	// 	if (getMessageType() is null) {
	// 		return super.getDetailedLogMessage(payload);
	// 	}
	// 	StringBuilder sb = getBaseLogMessage();
	// 	if (!CollectionUtils.isEmpty(getSessionAttributes())) {
	// 		sb.append(" attributes=").append(getSessionAttributes());
	// 	}
	// 	if (!CollectionUtils.isEmpty(cast(Map!(string, List!string)) getHeader(NATIVE_HEADERS))) {
	// 		sb.append(" nativeHeaders=").append(getHeader(NATIVE_HEADERS));
	// 	}
	// 	sb.append(getDetailedPayloadLogMessage(payload));
	// 	return sb.toString();
	// }

	// private StringBuilder getBaseLogMessage() {
	// 	StringBuilder sb = new StringBuilder();
	// 	SimpMessageType messageType = getMessageType();
	// 	sb.append(messageType !is null ? messageType.name() : SimpMessageType.OTHER);
	// 	string destination = getDestination();
	// 	if (destination !is null) {
	// 		sb.append(" destination=").append(destination);
	// 	}
	// 	string subscriptionId = getSubscriptionId();
	// 	if (subscriptionId !is null) {
	// 		sb.append(" subscriptionId=").append(subscriptionId);
	// 	}
	// 	sb.append(" session=").append(getSessionId());
	// 	Principal user = getUser();
	// 	if (user !is null) {
	// 		sb.append(" user=").append(user.getName());
	// 	}
	// 	return sb;
	// }


	// // Static factory methods and accessors

	// /**
	//  * Create an instance with
	//  * {@link hunt.framework.messaging.simp.SimpMessageType} {@code MESSAGE}.
	//  */
	// static SimpMessageHeaderAccessor create() {
	// 	return new SimpMessageHeaderAccessor(SimpMessageType.MESSAGE, null);
	// }

	// /**
	//  * Create an instance with the given
	//  * {@link hunt.framework.messaging.simp.SimpMessageType}.
	//  */
	// static SimpMessageHeaderAccessor create(SimpMessageType messageType) {
	// 	return new SimpMessageHeaderAccessor(messageType, null);
	// }

	// /**
	//  * Create an instance from the payload and headers of the given Message.
	//  */
	// static SimpMessageHeaderAccessor wrap(U)(Message!U message) {
	// 	return new SimpMessageHeaderAccessor(message);
	// }

	
	// static SimpMessageType getMessageType(Map!(string, Object) headers) {
	// 	return cast(SimpMessageType) headers.get(MESSAGE_TYPE_HEADER);
	// }

	
	// static string getDestination(Map!(string, Object) headers) {
	// 	return cast(string) headers.get(DESTINATION_HEADER);
	// }

	
	// static string getSubscriptionId(Map!(string, Object) headers) {
	// 	return cast(string) headers.get(SUBSCRIPTION_ID_HEADER);
	// }

	
	// static string getSessionId(Map!(string, Object) headers) {
	// 	return cast(string) headers.get(SESSION_ID_HEADER);
	// }

	
	
	// static Map!(string, Object) getSessionAttributes(Map!(string, Object) headers) {
	// 	return (Map!(string, Object)) headers.get(SESSION_ATTRIBUTES);
	// }

	
	// static Principal getUser(Map!(string, Object) headers) {
	// 	return (Principal) headers.get(USER_HEADER);
	// }

	
	// static long[] getHeartbeat(Map!(string, Object) headers) {
	// 	return (long[]) headers.get(HEART_BEAT_HEADER);
	// }

}
