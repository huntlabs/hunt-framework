/*
 * Copyright 2002-2018 the original author or authors.
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

module hunt.framework.messaging.simp.stomp;

import hunt.container;


// import org.springframework.util.Assert;
// import org.springframework.util.LinkedMultiValueMap;
// import org.springframework.util.MimeType;
// import org.springframework.util.MimeTypeUtils;
// import org.springframework.util.MultiValueMap;
// import org.springframework.util.ObjectUtils;
// import org.springframework.util.StringUtils;

/**
 * Represents STOMP frame headers.
 *
 * <p>In addition to the normal methods defined by {@link Map}, this class offers
 * the following convenience methods:
 * <ul>
 * <li>{@link #getFirst(string)} return the first value for a header name</li>
 * <li>{@link #add(string, string)} add to the list of values for a header name</li>
 * <li>{@link #set(string, string)} set a header name to a single string value</li>
 * </ul>
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 * @see <a href="http://stomp.github.io/stomp-specification-1.2.html#Frames_and_Headers">
 * http://stomp.github.io/stomp-specification-1.2.html#Frames_and_Headers</a>
 */
class StompHeaders : MultiValueMap<string, string>, Serializable {


	// Standard headers (as defined in the spec)

	enum string CONTENT_TYPE = "content-type"; // SEND, MESSAGE, ERROR

	enum string CONTENT_LENGTH = "content-length"; // SEND, MESSAGE, ERROR

	enum string RECEIPT = "receipt"; // any client frame other than CONNECT

	// CONNECT

	enum string HOST = "host";

	enum string ACCEPT_VERSION = "accept-version";

	enum string LOGIN = "login";

	enum string PASSCODE = "passcode";

	enum string HEARTBEAT = "heart-beat";

	// CONNECTED

	enum string SESSION = "session";

	enum string SERVER = "server";

	// SEND

	enum string DESTINATION = "destination";

	// SUBSCRIBE, UNSUBSCRIBE

	enum string ID = "id";

	enum string ACK = "ack";

	// MESSAGE

	enum string SUBSCRIPTION = "subscription";

	enum string MESSAGE_ID = "message-id";

	// RECEIPT

	enum string RECEIPT_ID = "receipt-id";


	private Map<string, List!(string)> headers;


	/**
	 * Create a new instance to be populated with new header values.
	 */
	this() {
		this(new LinkedMultiValueMap<>(4), false);
	}

	private this(Map<string, List!(string)> headers,  readOnly) {
		Assert.notNull(headers, "'headers' must not be null");
		if (readOnly) {
			Map<string, List!(string)> map = new LinkedMultiValueMap<>(headers.size());
			headers.forEach((key, value) -> map.put(key, Collections.unmodifiableList(value)));
			this.headers = Collections.unmodifiableMap(map);
		}
		else {
			this.headers = headers;
		}
	}


	/**
	 * Set the content-type header.
	 * Applies to the SEND, MESSAGE, and ERROR frames.
	 */
	void setContentType(MimeType mimeType) {
		if (mimeType !is null) {
			Assert.isTrue(!mimeType.isWildcardType(), "'Content-Type' cannot contain wildcard type '*'");
			Assert.isTrue(!mimeType.isWildcardSubtype(), "'Content-Type' cannot contain wildcard subtype '*'");
			set(CONTENT_TYPE, mimeType.toString());
		}
		else {
			set(CONTENT_TYPE, null);
		}
	}

	/**
	 * Return the content-type header value.
	 */
	
	MimeType getContentType() {
		string value = getFirst(CONTENT_TYPE);
		return (StringUtils.hasLength(value) ? MimeTypeUtils.parseMimeType(value) : null);
	}

	/**
	 * Set the content-length header.
	 * Applies to the SEND, MESSAGE, and ERROR frames.
	 */
	void setContentLength(long contentLength) {
		set(CONTENT_LENGTH, Long.toString(contentLength));
	}

	/**
	 * Return the content-length header or -1 if unknown.
	 */
	long getContentLength() {
		string value = getFirst(CONTENT_LENGTH);
		return (value !is null ? Long.parseLong(value) : -1);
	}

	/**
	 * Set the receipt header.
	 * Applies to any client frame other than CONNECT.
	 */
	void setReceipt(string receipt) {
		set(RECEIPT, receipt);
	}

	/**
	 * Get the receipt header.
	 */
	
	string getReceipt() {
		return getFirst(RECEIPT);
	}

	/**
	 * Set the host header.
	 * Applies to the CONNECT frame.
	 */
	void setHost(string host) {
		set(HOST, host);
	}

	/**
	 * Get the host header.
	 */
	
	string getHost() {
		return getFirst(HOST);
	}

	/**
	 * Set the accept-version header. Must be one of "1.1", "1.2", or both.
	 * Applies to the CONNECT frame.
	 * @since 5.0.7
	 */
	void setAcceptVersion(string... acceptVersions) {
		if (ObjectUtils.isEmpty(acceptVersions)) {
			set(ACCEPT_VERSION, null);
			return;
		}
		Arrays.stream(acceptVersions).forEach(version ->
				Assert.isTrue(version !is null && (version.equals("1.1") || version.equals("1.2")),
						"Invalid version: " ~ version));
		set(ACCEPT_VERSION, StringUtils.arrayToCommaDelimitedString(acceptVersions));
	}

	/**
	 * Get the accept-version header.
	 * @since 5.0.7
	 */
	
	string[] getAcceptVersion() {
		string value = getFirst(ACCEPT_VERSION);
		return value !is null ? StringUtils.commaDelimitedListToStringArray(value) : null;
	}

	/**
	 * Set the login header.
	 * Applies to the CONNECT frame.
	 */
	void setLogin(string login) {
		set(LOGIN, login);
	}

	/**
	 * Get the login header.
	 */
	
	string getLogin() {
		return getFirst(LOGIN);
	}

	/**
	 * Set the passcode header.
	 * Applies to the CONNECT frame.
	 */
	void setPasscode(string passcode) {
		set(PASSCODE, passcode);
	}

	/**
	 * Get the passcode header.
	 */
	
	string getPasscode() {
		return getFirst(PASSCODE);
	}

	/**
	 * Set the heartbeat header.
	 * Applies to the CONNECT and CONNECTED frames.
	 */
	void setHeartbeat(long[] heartbeat) {
		if (heartbeat is null || heartbeat.length != 2) {
			throw new IllegalArgumentException("Heart-beat array must be of length 2, not " ~
					(heartbeat !is null ? heartbeat.length : "null"));
		}
		string value = heartbeat[0] ~ "," ~ heartbeat[1];
		if (heartbeat[0] < 0 || heartbeat[1] < 0) {
			throw new IllegalArgumentException("Heart-beat values cannot be negative: " ~ value);
		}
		set(HEARTBEAT, value);
	}

	/**
	 * Get the heartbeat header.
	 */
	
	long[] getHeartbeat() {
		string rawValue = getFirst(HEARTBEAT);
		string[] rawValues = StringUtils.split(rawValue, ",");
		if (rawValues is null) {
			return null;
		}
		return new long[] {Long.valueOf(rawValues[0]), Long.valueOf(rawValues[1])};
	}

	/**
	 * Whether heartbeats are enabled. Returns {@code false} if
	 * {@link #setHeartbeat} is set to "0,0", and {@code true} otherwise.
	 */
	 isHeartbeatEnabled() {
		long[] heartbeat = getHeartbeat();
		return (heartbeat !is null && heartbeat[0] != 0 && heartbeat[1] != 0);
	}

	/**
	 * Set the session header.
	 * Applies to the CONNECTED frame.
	 */
	void setSession(string session) {
		set(SESSION, session);
	}

	/**
	 * Get the session header.
	 */
	
	string getSession() {
		return getFirst(SESSION);
	}

	/**
	 * Set the server header.
	 * Applies to the CONNECTED frame.
	 */
	void setServer(string server) {
		set(SERVER, server);
	}

	/**
	 * Get the server header.
	 * Applies to the CONNECTED frame.
	 */
	
	string getServer() {
		return getFirst(SERVER);
	}

	/**
	 * Set the destination header.
	 */
	void setDestination(string destination) {
		set(DESTINATION, destination);
	}

	/**
	 * Get the destination header.
	 * Applies to the SEND, SUBSCRIBE, and MESSAGE frames.
	 */
	
	string getDestination() {
		return getFirst(DESTINATION);
	}

	/**
	 * Set the id header.
	 * Applies to the SUBSCR0BE, UNSUBSCRIBE, and ACK or NACK frames.
	 */
	void setId(string id) {
		set(ID, id);
	}

	/**
	 * Get the id header.
	 */
	
	string getId() {
		return getFirst(ID);
	}

	/**
	 * Set the ack header to one of "auto", "client", or "client-individual".
	 * Applies to the SUBSCRIBE and MESSAGE frames.
	 */
	void setAck(string ack) {
		set(ACK, ack);
	}

	/**
	 * Get the ack header.
	 */
	
	string getAck() {
		return getFirst(ACK);
	}

	/**
	 * Set the login header.
	 * Applies to the MESSAGE frame.
	 */
	void setSubscription(string subscription) {
		set(SUBSCRIPTION, subscription);
	}

	/**
	 * Get the subscription header.
	 */
	
	string getSubscription() {
		return getFirst(SUBSCRIPTION);
	}

	/**
	 * Set the message-id header.
	 * Applies to the MESSAGE frame.
	 */
	void setMessageId(string messageId) {
		set(MESSAGE_ID, messageId);
	}

	/**
	 * Get the message-id header.
	 */
	
	string getMessageId() {
		return getFirst(MESSAGE_ID);
	}

	/**
	 * Set the receipt-id header.
	 * Applies to the RECEIPT frame.
	 */
	void setReceiptId(string receiptId) {
		set(RECEIPT_ID, receiptId);
	}

	/**
	 * Get the receipt header.
	 */
	
	string getReceiptId() {
		return getFirst(RECEIPT_ID);
	}

	/**
	 * Return the first header value for the given header name, if any.
	 * @param headerName the header name
	 * @return the first header value, or {@code null} if none
	 */
	override
	
	string getFirst(string headerName) {
		List!(string) headerValues = this.headers.get(headerName);
		return headerValues !is null ? headerValues.get(0) : null;
	}

	/**
	 * Add the given, single header value under the given name.
	 * @param headerName the header name
	 * @param headerValue the header value
	 * @throws UnsupportedOperationException if adding headers is not supported
	 * @see #put(string, List)
	 * @see #set(string, string)
	 */
	override
	void add(string headerName, string headerValue) {
		List!(string) headerValues = this.headers.computeIfAbsent(headerName, k -> new LinkedList<>());
		headerValues.add(headerValue);
	}

	override
	void addAll(string headerName, List<string> headerValues) {
		List!(string) currentValues = this.headers.computeIfAbsent(headerName, k -> new LinkedList<>());
		currentValues.addAll(headerValues);
	}

	override
	void addAll(MultiValueMap<string, string> values) {
		values.forEach(this::addAll);
	}

	/**
	 * Set the given, single header value under the given name.
	 * @param headerName the header name
	 * @param headerValue the header value
	 * @throws UnsupportedOperationException if adding headers is not supported
	 * @see #put(string, List)
	 * @see #add(string, string)
	 */
	override
	void set(string headerName, string headerValue) {
		List!(string) headerValues = new LinkedList!(string)();
		headerValues.add(headerValue);
		this.headers.put(headerName, headerValues);
	}

	override
	void setAll(Map<string, string> values) {
		values.forEach(this::set);
	}

	override
	Map<string, string> toSingleValueMap() {
		LinkedHashMap<string, string> singleValueMap = new LinkedHashMap<>(this.headers.size());
		this.headers.forEach((key, value) -> singleValueMap.put(key, value.get(0)));
		return singleValueMap;
	}


	// Map implementation

	override
	int size() {
		return this.headers.size();
	}

	override
	 isEmpty() {
		return this.headers.isEmpty();
	}

	override
	 containsKey(Object key) {
		return this.headers.containsKey(key);
	}

	override
	 containsValue(Object value) {
		return this.headers.containsValue(value);
	}

	override
	List!(string) get(Object key) {
		return this.headers.get(key);
	}

	override
	List!(string) put(string key, List!(string) value) {
		return this.headers.put(key, value);
	}

	override
	List!(string) remove(Object key) {
		return this.headers.remove(key);
	}

	override
	void putAll(Map<string, List!(string)> map) {
		this.headers.putAll(map);
	}

	override
	void clear() {
		this.headers.clear();
	}

	override
	Set!(string) keySet() {
		return this.headers.keySet();
	}

	override
	Collection<List!(string)> values() {
		return this.headers.values();
	}

	override
	Set<Entry<string, List!(string)>> entrySet() {
		return this.headers.entrySet();
	}


	override
	bool opEquals(Object other) {
		return (this == other || (other instanceof StompHeaders &&
				this.headers.equals(((StompHeaders) other).headers)));
	}

	override
	size_t toHash() @trusted nothrow {
		return this.headers.toHash();
	}

	override
	string toString() {
		return this.headers.toString();
	}


	/**
	 * Return a {@code StompHeaders} object that can only be read, not written to.
	 */
	static StompHeaders readOnlyStompHeaders(Map<string, List!(string)> headers) {
		return new StompHeaders((headers !is null ? headers : Collections.emptyMap()), true);
	}

}
