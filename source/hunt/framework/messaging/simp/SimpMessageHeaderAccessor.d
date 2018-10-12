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

module hunt.framework.messaging.simp;

import java.security.Principal;
import java.util.List;
import hunt.container.Map;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.support.IdTimestampMessageHeaderInitializer;
import hunt.framework.messaging.support.MessageHeaderAccessor;
import hunt.framework.messaging.support.NativeMessageHeaderAccessor;
import org.springframework.util.Assert;
import org.springframework.util.CollectionUtils;

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
public class SimpMessageHeaderAccessor extends NativeMessageHeaderAccessor {

	private static final IdTimestampMessageHeaderInitializer headerInitializer;

	static {
		headerInitializer = new IdTimestampMessageHeaderInitializer();
		headerInitializer.setDisableIdGeneration();
		headerInitializer.setEnableTimestamp(false);
	}

	// SiMP header names

	public static final string DESTINATION_HEADER = "simpDestination";

	public static final string MESSAGE_TYPE_HEADER = "simpMessageType";

	public static final string SESSION_ID_HEADER = "simpSessionId";

	public static final string SESSION_ATTRIBUTES = "simpSessionAttributes";

	public static final string SUBSCRIPTION_ID_HEADER = "simpSubscriptionId";

	public static final string USER_HEADER = "simpUser";

	public static final string CONNECT_MESSAGE_HEADER = "simpConnectMessage";

	public static final string DISCONNECT_MESSAGE_HEADER = "simpDisconnectMessage";

	public static final string HEART_BEAT_HEADER = "simpHeartbeat";


	/**
	 * A header for internal use with "user" destinations where we need to
	 * restore the destination prior to sending messages to clients.
	 */
	public static final string ORIGINAL_DESTINATION = "simpOrigDestination";

	/**
	 * A header that indicates to the broker that the sender will ignore errors.
	 * The header is simply checked for presence or absence.
	 */
	public static final string IGNORE_ERROR = "simpIgnoreError";


	/**
	 * A constructor for creating new message headers.
	 * This constructor is protected. See factory methods in this and sub-classes.
	 */
	protected SimpMessageHeaderAccessor(SimpMessageType messageType,
			Map<string, List!(string)> externalSourceHeaders) {

		super(externalSourceHeaders);
		Assert.notNull(messageType, "MessageType must not be null");
		setHeader(MESSAGE_TYPE_HEADER, messageType);
		headerInitializer.initHeaders(this);
	}

	/**
	 * A constructor for accessing and modifying existing message headers. This
	 * constructor is protected. See factory methods in this and sub-classes.
	 */
	protected SimpMessageHeaderAccessor(Message<?> message) {
		super(message);
		headerInitializer.initHeaders(this);
	}


	override
	protected MessageHeaderAccessor createAccessor(Message<?> message) {
		return wrap(message);
	}

	public void setMessageTypeIfNotSet(SimpMessageType messageType) {
		if (getMessageType() is null) {
			setHeader(MESSAGE_TYPE_HEADER, messageType);
		}
	}

	
	public SimpMessageType getMessageType() {
		return (SimpMessageType) getHeader(MESSAGE_TYPE_HEADER);
	}

	public void setDestination(string destination) {
		setHeader(DESTINATION_HEADER, destination);
	}

	
	public string getDestination() {
		return (string) getHeader(DESTINATION_HEADER);
	}

	public void setSubscriptionId(string subscriptionId) {
		setHeader(SUBSCRIPTION_ID_HEADER, subscriptionId);
	}

	
	public string getSubscriptionId() {
		return (string) getHeader(SUBSCRIPTION_ID_HEADER);
	}

	public void setSessionId(string sessionId) {
		setHeader(SESSION_ID_HEADER, sessionId);
	}

	/**
	 * Return the id of the current session.
	 */
	
	public string getSessionId() {
		return (string) getHeader(SESSION_ID_HEADER);
	}

	/**
	 * A static alternative for access to the session attributes header.
	 */
	public void setSessionAttributes(Map!(string, Object) attributes) {
		setHeader(SESSION_ATTRIBUTES, attributes);
	}

	/**
	 * Return the attributes associated with the current session.
	 */
	
	
	public Map!(string, Object) getSessionAttributes() {
		return (Map!(string, Object)) getHeader(SESSION_ATTRIBUTES);
	}

	public void setUser(Principal principal) {
		setHeader(USER_HEADER, principal);
	}

	/**
	 * Return the user associated with the current session.
	 */
	
	public Principal getUser() {
		return (Principal) getHeader(USER_HEADER);
	}

	override
	public string getShortLogMessage(Object payload) {
		if (getMessageType() is null) {
			return super.getDetailedLogMessage(payload);
		}
		StringBuilder sb = getBaseLogMessage();
		if (!CollectionUtils.isEmpty(getSessionAttributes())) {
			sb.append(" attributes[").append(getSessionAttributes().size()).append("]");
		}
		sb.append(getShortPayloadLogMessage(payload));
		return sb.toString();
	}

	
	override
	public string getDetailedLogMessage(Object payload) {
		if (getMessageType() is null) {
			return super.getDetailedLogMessage(payload);
		}
		StringBuilder sb = getBaseLogMessage();
		if (!CollectionUtils.isEmpty(getSessionAttributes())) {
			sb.append(" attributes=").append(getSessionAttributes());
		}
		if (!CollectionUtils.isEmpty((Map<string, List!(string)>) getHeader(NATIVE_HEADERS))) {
			sb.append(" nativeHeaders=").append(getHeader(NATIVE_HEADERS));
		}
		sb.append(getDetailedPayloadLogMessage(payload));
		return sb.toString();
	}

	private StringBuilder getBaseLogMessage() {
		StringBuilder sb = new StringBuilder();
		SimpMessageType messageType = getMessageType();
		sb.append(messageType !is null ? messageType.name() : SimpMessageType.OTHER);
		string destination = getDestination();
		if (destination !is null) {
			sb.append(" destination=").append(destination);
		}
		string subscriptionId = getSubscriptionId();
		if (subscriptionId !is null) {
			sb.append(" subscriptionId=").append(subscriptionId);
		}
		sb.append(" session=").append(getSessionId());
		Principal user = getUser();
		if (user !is null) {
			sb.append(" user=").append(user.getName());
		}
		return sb;
	}


	// Static factory methods and accessors

	/**
	 * Create an instance with
	 * {@link hunt.framework.messaging.simp.SimpMessageType} {@code MESSAGE}.
	 */
	public static SimpMessageHeaderAccessor create() {
		return new SimpMessageHeaderAccessor(SimpMessageType.MESSAGE, null);
	}

	/**
	 * Create an instance with the given
	 * {@link hunt.framework.messaging.simp.SimpMessageType}.
	 */
	public static SimpMessageHeaderAccessor create(SimpMessageType messageType) {
		return new SimpMessageHeaderAccessor(messageType, null);
	}

	/**
	 * Create an instance from the payload and headers of the given Message.
	 */
	public static SimpMessageHeaderAccessor wrap(Message<?> message) {
		return new SimpMessageHeaderAccessor(message);
	}

	
	public static SimpMessageType getMessageType(Map!(string, Object) headers) {
		return (SimpMessageType) headers.get(MESSAGE_TYPE_HEADER);
	}

	
	public static string getDestination(Map!(string, Object) headers) {
		return (string) headers.get(DESTINATION_HEADER);
	}

	
	public static string getSubscriptionId(Map!(string, Object) headers) {
		return (string) headers.get(SUBSCRIPTION_ID_HEADER);
	}

	
	public static string getSessionId(Map!(string, Object) headers) {
		return (string) headers.get(SESSION_ID_HEADER);
	}

	
	
	public static Map!(string, Object) getSessionAttributes(Map!(string, Object) headers) {
		return (Map!(string, Object)) headers.get(SESSION_ATTRIBUTES);
	}

	
	public static Principal getUser(Map!(string, Object) headers) {
		return (Principal) headers.get(USER_HEADER);
	}

	
	public static long[] getHeartbeat(Map!(string, Object) headers) {
		return (long[]) headers.get(HEART_BEAT_HEADER);
	}

}
