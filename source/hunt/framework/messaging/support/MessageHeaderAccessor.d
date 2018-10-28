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

module hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.framework.messaging.IdGenerator;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessageHeaders;

import hunt.http.codec.http.model.MimeTypes;

import hunt.lang.Charset;
import hunt.lang.object;
import hunt.lang.Long;
import hunt.container;
import hunt.datetime;
import hunt.string.PatternMatchUtils;
import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.util.ObjectUtils;

import std.algorithm;
import std.conv;
import std.range.primitives;
import std.string;
import std.uuid;


/**
 * Callback interface for initializing a {@link MessageHeaderAccessor}.
 *
 * @author Rossen Stoyanchev
 * @since 4.1
 */
interface MessageHeaderInitializer {

	/**
	 * Initialize the given {@code MessageHeaderAccessor}.
	 * @param headerAccessor the MessageHeaderAccessor to initialize
	 */
	void initHeaders(MessageHeaderAccessor headerAccessor);

}

alias Charset = string;

/**
 * A base for classes providing strongly typed getters and setters as well as
 * behavior around specific categories of headers (e.g. STOMP headers).
 * Supports creating new headers, modifying existing headers (when still mutable),
 * or copying and modifying existing headers.
 *
 * <p>The method {@link #getMessageHeaders()} provides access to the underlying,
 * fully-prepared {@link MessageHeaders} that can then be used as-is (i.e.
 * without copying) to create a single message as follows:
 *
 * <pre class="code">
 * MessageHeaderAccessor accessor = new MessageHeaderAccessor();
 * accessor.setHeader("foo", "bar");
 * Message message = MessageHelper.createMessage("payload", accessor.getMessageHeaders());
 * </pre>
 *
 * <p>After the above, by default the {@code MessageHeaderAccessor} becomes
 * immutable. However it is possible to leave it mutable for further initialization
 * in the same thread, for example:
 *
 * <pre class="code">
 * MessageHeaderAccessor accessor = new MessageHeaderAccessor();
 * accessor.setHeader("foo", "bar");
 * accessor.setLeaveMutable(true);
 * Message message = MessageHelper.createMessage("payload", accessor.getMessageHeaders());
 *
 * // later on in the same thread...
 *
 * MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message);
 * accessor.setHeader("bar", "baz");
 * accessor.setImmutable();
 * </pre>
 *
 * <p>The method {@link #toMap()} returns a copy of the underlying headers. It can
 * be used to prepare multiple messages from the same {@code MessageHeaderAccessor}
 * instance:
 * <pre class="code">
 * MessageHeaderAccessor accessor = new MessageHeaderAccessor();
 * MessageBuilder builder = MessageBuilder.withPayload("payload").setHeaders(accessor);
 *
 * accessor.setHeader("foo", "bar1");
 * Message message1 = builder.build();
 *
 * accessor.setHeader("foo", "bar2");
 * Message message2 = builder.build();
 *
 * accessor.setHeader("foo", "bar3");
 * Message  message3 = builder.build();
 * </pre>
 *
 * <p>However note that with the above style, the header accessor is shared and
 * cannot be re-obtained later on. Alternatively it is also possible to create
 * one {@code MessageHeaderAccessor} per message:
 *
 * <pre class="code">
 * MessageHeaderAccessor accessor1 = new MessageHeaderAccessor();
 * accessor.set("foo", "bar1");
 * Message message1 = MessageHelper.createMessage("payload", accessor1.getMessageHeaders());
 *
 * MessageHeaderAccessor accessor2 = new MessageHeaderAccessor();
 * accessor.set("foo", "bar2");
 * Message message2 = MessageHelper.createMessage("payload", accessor2.getMessageHeaders());
 *
 * MessageHeaderAccessor accessor3 = new MessageHeaderAccessor();
 * accessor.set("foo", "bar3");
 * Message message3 = MessageHelper.createMessage("payload", accessor3.getMessageHeaders());
 * </pre>
 *
 * <p>Note that the above examples aim to demonstrate the general idea of using
 * header accessors. The most likely usage however is through subclasses.
 *
 * @author Rossen Stoyanchev
 * @author Juergen Hoeller
 * @since 4.0
 */
class MessageHeaderAccessor {

	/**
	 * The default charset used for headers.
	 */
	enum Charset DEFAULT_CHARSET = StandardCharsets.UTF_8;

	private __gshared MimeType[] READABLE_MIME_TYPES;


	private MutableMessageHeaders headers;

	private bool leaveMutable = false;

	private bool modified = false;

	private bool enableTimestamp = false;

	
	private IdGenerator idGenerator;

	shared static this() {
		READABLE_MIME_TYPES = [
			MimeType.APPLICATION_JSON, MimeType.APPLICATION_XML,
			new MimeType("text", new MimeType("*")), 
			new MimeType("application", new MimeType("*+json")), 
			new MimeType("application", new MimeType("*+xml"))
		];
	}


	/**
	 * A constructor to create new headers.
	 */
	this() {
		this(null);
	}

	/**
	 * A constructor accepting the headers of an existing message to copy.
	 * @param message a message to copy the headers from, or {@code null} if none
	 */
	this(MessageBase message) {
		this.headers = new MutableMessageHeaders(message !is null ? message.getHeaders() : null);
	}


	/**
	 * Build a 'nested' accessor for the given message.
	 * @param message the message to build a new accessor for
	 * @return the nested accessor (typically a specific subclass)
	 */
	protected MessageHeaderAccessor createAccessor(MessageBase message) {
		return new MessageHeaderAccessor(message);
	}


	// Configuration properties

	/**
	 * By default when {@link #getMessageHeaders()} is called, {@code "this"}
	 * {@code MessageHeaderAccessor} instance can no longer be used to modify the
	 * underlying message headers and the returned {@code MessageHeaders} is immutable.
	 * <p>However when this is set to {@code true}, the returned (underlying)
	 * {@code MessageHeaders} instance remains mutable. To make further modifications
	 * continue to use the same accessor instance or re-obtain it via:<br>
	 * {@link MessageHeaderAccessor#getAccessor(Message, Class)
	 * MessageHeaderAccessor.getAccessor(Message, Class)}
	 * <p>When modifications are complete use {@link #setImmutable()} to prevent
	 * further changes. The intended use case for this mechanism is initialization
	 * of a Message within a single thread.
	 * <p>By default this is set to {@code false}.
	 * @since 4.1
	 */
	void setLeaveMutable(bool leaveMutable) {
		assert(this.headers.isMutable(), "Already immutable");
		this.leaveMutable = leaveMutable;
	}

	/**
	 * By default when {@link #getMessageHeaders()} is called, {@code "this"}
	 * {@code MessageHeaderAccessor} instance can no longer be used to modify the
	 * underlying message headers. However if {@link #setLeaveMutable()}
	 * is used, this method is necessary to indicate explicitly when the
	 * {@code MessageHeaders} instance should no longer be modified.
	 * @since 4.1
	 */
	void setImmutable() {
		this.headers.setImmutable();
	}

	/**
	 * Whether the underlying headers can still be modified.
	 * @since 4.1
	 */
	bool isMutable() {
		return this.headers.isMutable();
	}

	/**
	 * Mark the underlying message headers as modified.
	 * @param modified typically {@code true}, or {@code false} to reset the flag
	 * @since 4.1
	 */
	protected void setModified(bool modified) {
		this.modified = modified;
	}

	/**
	 * Check whether the underlying message headers have been marked as modified.
	 * @return {@code true} if the flag has been set, {@code false} otherwise
	 */
	bool isModified() {
		return this.modified;
	}

	/**
	 * A package private mechanism to enables the automatic addition of the
	 * {@link hunt.framework.messaging.MessageHeaders#TIMESTAMP} header.
	 * <p>By default, this property is set to {@code false}.
	 * @see IdTimestampMessageHeaderInitializer
	 */
	void setEnableTimestamp(bool enableTimestamp) {
		this.enableTimestamp = enableTimestamp;
	}

	/**
	 * A package-private mechanism to configure the IdGenerator strategy to use.
	 * <p>By default this property is not set in which case the default IdGenerator
	 * in {@link hunt.framework.messaging.MessageHeaders} is used.
	 * @see IdTimestampMessageHeaderInitializer
	 */
	void setIdGenerator(IdGenerator idGenerator) {
		this.idGenerator = idGenerator;
	}


	// Accessors for the resulting MessageHeaders

	/**
	 * Return the underlying {@code MessageHeaders} instance.
	 * <p>Unless {@link #setLeaveMutable()} was set to {@code true}, after
	 * this call, the headers are immutable and this accessor can no longer
	 * modify them.
	 * <p>This method always returns the same {@code MessageHeaders} instance if
	 * invoked multiples times. To obtain a copy of the underlying headers, use
	 * {@link #toMessageHeaders()} or {@link #toMap()} instead.
	 * @since 4.1
	 */
	MessageHeaders getMessageHeaders() {
		if (!this.leaveMutable) {
			setImmutable();
		}
		return this.headers;
	}

	/**
	 * Return a copy of the underlying header values as a {@link MessageHeaders} object.
	 * <p>This method can be invoked many times, with modifications in between
	 * where each new call returns a fresh copy of the current header values.
	 * @since 4.1
	 */
	MessageHeaders toMessageHeaders() {
		return new MessageHeaders(this.headers);
	}

	/**
	 * Return a copy of the underlying header values as a plain {@link Map} object.
	 * <p>This method can be invoked many times, with modifications in between
	 * where each new call returns a fresh copy of the current header values.
	 */
	Map!(string, Object) toMap() {
		return new HashMap!(string, Object)(this.headers);
	}


	// Generic header accessors

	/**
	 * Retrieve the value for the header with the given name.
	 * @param headerName the name of the header
	 * @return the associated value, or {@code null} if none found
	 */
	
	Object getHeader(string headerName) {
		return this.headers.get(headerName);
	}

	T getHeaderAs(T)(string headerName) {
		return this.headers.getAs!(T)(headerName);
	}

	void setHeader(T)(string name, T value) if(!is(T == class)) {
		setHeader(name, new Nullable!T(value));
	}

	/**
	 * Set the value for the given header name.
	 * <p>If the provided value is {@code null}, the header will be removed.
	 */
	void setHeader(string name, Object value) {
		if (isReadOnly(name)) {
			throw new IllegalArgumentException("'" ~ name ~ "' header is read-only");
		}
		verifyType(name, value);
		if (value !is null) {
			// Modify header if necessary
			if (!ObjectUtils.nullSafeEquals(value, getHeader(name))) {
				this.modified = true;
				this.headers.getRawHeaders().put(name, value);
			}
		}
		else {
			// Remove header if available
			if (this.headers.containsKey(name)) {
				this.modified = true;
				this.headers.getRawHeaders().remove(name);
			}
		}
	}

	protected void verifyType(string headerName, Object headerValue) {
		if (!headerName.empty && headerValue !is null) {
			if (MessageHeaders.ERROR_CHANNEL == headerName ||
					MessageHeaders.REPLY_CHANNEL.endsWith(headerName)) {
				MessageChannel mc = cast(MessageChannel)headerValue;
				Nullable!string str = cast(Nullable!string)headerValue;
				
				if (mc is null && str is null) {
					throw new IllegalArgumentException(
							"'" ~ headerName ~ "' header value must be a MessageChannel or string");
				}
			}
		}
	}

	/**
	 * Set the value for the given header name only if the header name is not
	 * already associated with a value.
	 */
	void setHeaderIfAbsent(string name, Object value) {
		if (getHeader(name) is null) {
			setHeader(name, value);
		}
	}

	/**
	 * Remove the value for the given header name.
	 */
	void removeHeader(string headerName) {
		if (!headerName.empty && !isReadOnly(headerName)) {
			setHeader(headerName, null);
		}
	}

	/**
	 * Removes all headers provided via array of 'headerPatterns'.
	 * <p>As the name suggests, array may contain simple matching patterns for header
	 * names. Supported pattern styles are: "xxx*", "*xxx", "*xxx*" and "xxx*yyy".
	 */
	void removeHeaders(string[] headerPatterns...) {
		List!(string) headersToRemove = new ArrayList!string();
		foreach (string pattern ; headerPatterns) {
			if (!pattern.empty()){
				if (pattern.canFind("*")){
					headersToRemove.addAll(getMatchingHeaderNames(pattern, this.headers));
				}
				else {
					headersToRemove.add(pattern);
				}
			}
		}
		foreach (string headerToRemove ; headersToRemove) {
			removeHeader(headerToRemove);
		}
	}

	private List!(string) getMatchingHeaderNames(string pattern, Map!(string, Object) headers) {
		List!(string) matchingHeaderNames = new ArrayList!string();
		if (headers !is null) {
			foreach (string key ; headers.byKey) {
				if (PatternMatchUtils.simpleMatch(pattern, key)) {
					matchingHeaderNames.add(key);
				}
			}
		}
		return matchingHeaderNames;
	}

	/**
	 * Copy the name-value pairs from the provided Map.
	 * <p>This operation will overwrite any existing values. Use
	 * {@link #copyHeadersIfAbsent(Map)} to avoid overwriting values.
	 */
	// void copyHeaders(Map<string, ?> headersToCopy) {
	// 	if (headersToCopy !is null) {
	// 		headersToCopy.forEach((key, value) -> {
	// 			if (!isReadOnly(key)) {
	// 				setHeader(key, value);
	// 			}
	// 		});
	// 	}
	// }

	/**
	 * Copy the name-value pairs from the provided Map.
	 * <p>This operation will <em>not</em> overwrite any existing values.
	 */
	// void copyHeadersIfAbsent(Map<string, ?> headersToCopy) {
	// 	if (headersToCopy !is null) {
	// 		headersToCopy.forEach((key, value) -> {
	// 			if (!isReadOnly(key)) {
	// 				setHeaderIfAbsent(key, value);
	// 			}
	// 		});
	// 	}
	// }

	protected bool isReadOnly(string headerName) {
		return (MessageHeaders.ID == (headerName) || MessageHeaders.TIMESTAMP == (headerName));
	}


	// Specific header accessors

	
	UUID getId() {
		Object value = getHeader(MessageHeaders.ID);
		if (value is null) {
			return UUID.init;
		}

		auto uu = cast(Nullable!UUID)value;
		if(uu is null) {
			auto us = cast(Nullable!string)value;
			if(us is null)
				throw new Exception("bad type");
			else 
				return UUID(us.value);
		} else {
			return uu.value;
		}

		// return (value instanceof UUID ? (UUID) value : UUID.fromString(value.toString()));
	}

	
	Long getTimestamp() {
		Object value = getHeader(MessageHeaders.TIMESTAMP);
		if (value is null) {
			return null;
		}

		auto vl = cast(Long)value;
		if(vl is null) {
			auto vs = cast(Nullable!string)value;
			if(vs is null)
				throw new Exception("bad type");
			else 
				return new Long(vs.value);
		} else {
			return vl;
		}

		// return (value instanceof Long ? (Long) value : Long.parseLong(value.toString()));
	}

	void setContentType(MimeType contentType) {
		setHeader(MessageHeaders.CONTENT_TYPE, contentType);
	}

	
	MimeType getContentType() {
		Object value = getHeader(MessageHeaders.CONTENT_TYPE);
		if (value is null) {
			return null;
		}
		MimeType mt = cast(MimeType) value;
		if(mt !is null)
			return mt;

		auto vs = cast(Nullable!string)value;
		if(vs is null)
			throw new Exception("bad type");
		else 
			return new MimeType(vs.value);
		// return (value instanceof MimeType ? (MimeType) value : MimeType.valueOf(value.toString()));
	}

	private Charset getCharset() {
		MimeType contentType = getContentType();
		Charset charset = (contentType !is null ? contentType.getCharsetString() : null);
		return (charset !is null ? charset : DEFAULT_CHARSET);
	}

	void setReplyChannelName(string replyChannelName) {
		setHeader(MessageHeaders.REPLY_CHANNEL, new Nullable!string(replyChannelName));
	}

	void setReplyChannel(MessageChannel replyChannel) {
		setHeader(MessageHeaders.REPLY_CHANNEL, cast(Object)replyChannel);
	}

	
	Object getReplyChannel() {
		return getHeader(MessageHeaders.REPLY_CHANNEL);
	}

	void setErrorChannelName(string errorChannelName) {
		setHeader(MessageHeaders.ERROR_CHANNEL, new Nullable!string(errorChannelName));
	}

	void setErrorChannel(MessageChannel errorChannel) {
		setHeader(MessageHeaders.ERROR_CHANNEL, cast(Object)errorChannel);
	}

	
	Object getErrorChannel() {
		return getHeader(MessageHeaders.ERROR_CHANNEL);
	}


	// Log message stuff

	/**
	 * Return a concise message for logging purposes.
	 * @param payload the payload that corresponds to the headers.
	 * @return the message
	 */
	string getShortLogMessage(Object payload) {
		return "headers=" ~ this.headers.toString() ~ getShortPayloadLogMessage(payload);
	}

	/**
	 * Return a more detailed message for logging purposes.
	 * @param payload the payload that corresponds to the headers.
	 * @return the message
	 */
	string getDetailedLogMessage(Object payload) {
		return "headers=" ~ this.headers.toString() ~ getDetailedPayloadLogMessage(payload);
	}

	protected string getShortPayloadLogMessage(Object payload) {
		auto textPayload = cast(Nullable!string)payload;
		if (textPayload !is null) {
			string payloadText = textPayload.value;
			return (payloadText.length < 80) ?
				" payload=" ~ payloadText :
				" payload=" ~ payloadText[0 ..80] ~ "...(truncated)";
		}
		
		auto bytesPayload = cast(Nullable!(byte[]))payload;
		if (bytesPayload !is null) {
			byte[] bytes = bytesPayload.value;
			if (isReadableContentType()) {
				return (bytes.length < 80) ?
						" payload=" ~ cast(string)(bytes) :
						" payload=" ~ cast(string)(bytes[0..80]) ~ "...(truncated)";
			}
			else {
				return " payload=byte[" ~ to!string(bytes.length) ~ "]";
			}
		}
		else {
			string payloadText = payload.toString();
			return (payloadText.length < 80) ?
					" payload=" ~ payloadText :
					" payload=" ~ ObjectUtils.identityToString(payload);
		}
	}

	protected string getDetailedPayloadLogMessage(Object payload) {
		auto textPayload = cast(Nullable!string)payload;
		if (textPayload !is null) {
			return " payload=" ~ textPayload.value;
		}
		
		auto bytesPayload = cast(Nullable!(byte[]))payload;
		if (bytesPayload !is null) {
			byte[] bytes = bytesPayload.value;
			if (isReadableContentType()) {
				return " payload=" ~ cast(string)(bytes);
			} else {
				return " payload=byte[" ~ to!string(bytes.length) ~ "]";
			}
		}
		else {
			return " payload=" ~ payload.toString();
		}
	}

	protected bool isReadableContentType() {
		MimeType contentType = getContentType();
		implementationMissing(false);
		foreach (MimeType mimeType ; READABLE_MIME_TYPES) {
			// if (mimeType.includes(contentType)) {
			// 	return true;
			// }
		}
		return false;
	}

	override
	string toString() {
		return typeid(this).name ~ " [headers=" ~ this.headers.toString() ~ "]";
	}


	// Static factory methods

	/**
	 * Return the original {@code MessageHeaderAccessor} used to create the headers
	 * of the given {@code Message}, or {@code null} if that's not available or if
	 * its type does not match the required type.
	 * <p>This is for cases where the existence of an accessor is strongly expected
	 * (followed up with an assertion) or where an accessor will be created otherwise.
	 * @param message the message to get an accessor for
	 * @param requiredType the required accessor type (or {@code null} for any)
	 * @return an accessor instance of the specified type, or {@code null} if none
	 * @since 4.1
	 */
	
	static T getAccessor(T)(MessageBase message message) {
		return getAccessor!T(message.getHeaders());
	}

	/**
	 * A variation of {@link #getAccessor(hunt.framework.messaging.Message, Class)}
	 * with a {@code MessageHeaders} instance instead of a {@code Message}.
	 * <p>This is for cases when a full message may not have been created yet.
	 * @param messageHeaders the message headers to get an accessor for
	 * @param requiredType the required accessor type (or {@code null} for any)
	 * @return an accessor instance of the specified type, or {@code null} if none
	 * @since 4.1
	 */
	
	
	static T getAccessor(T)(MessageHeaders messageHeaders) {
		MutableMessageHeaders mutableHeaders = cast(MutableMessageHeaders) messageHeaders;

		if (mutableHeaders !is null) {
			MessageHeaderAccessor headerAccessor = mutableHeaders.getAccessor();
			if (typeid(T) == typeid(headerAccessor))  {
				return cast(T) headerAccessor;
			}
		}
		return null;
	}

	/**
	 * Return a mutable {@code MessageHeaderAccessor} for the given message attempting
	 * to match the type of accessor used to create the message headers, or otherwise
	 * wrapping the message with a {@code MessageHeaderAccessor} instance.
	 * <p>This is for cases where a header needs to be updated in generic code
	 * while preserving the accessor type for downstream processing.
	 * @return an accessor of the required type (never {@code null})
	 * @since 4.1
	 */
	static MessageHeaderAccessor getMutableAccessor(MessageBase message) {
			MutableMessageHeaders mutableHeaders = cast(MutableMessageHeaders) message.getHeaders();
		if (mutableHeaders !is null) {
			MessageHeaderAccessor accessor = mutableHeaders.getAccessor();
			return (accessor.isMutable() ? accessor : accessor.createAccessor(message));
		}
		return new MessageHeaderAccessor(message);
	}


	
	private class MutableMessageHeaders : MessageHeaders {

		private bool mutable = true;

		this(Map!(string, Object) headers) {
			super(headers, &MessageHeaders.ID_VALUE_NONE, (-1L));
		}

		override
		Map!(string, Object) getRawHeaders() {
			assert(this.mutable, "Already immutable");
			return super.getRawHeaders();
		}

		void setImmutable() {
			if (!this.mutable) {
				return;
			}

			if (getId().empty) {
				// UUID id = randomUUID();

				IdGenerator idGenerator = this.outer.idGenerator;
				if(idGenerator is null)
					idGenerator = MessageHeaders.getIdGenerator();
				UUID id = idGenerator.generateId();
				if (id != MessageHeaders.ID_VALUE_NONE) {
					getRawHeaders().put(ID, new Nullable!UUID(id));
				}
			}

			if (getTimestamp() is null) {
				if (this.outer.enableTimestamp) {
					Long timestamp = new Long(DateTimeHelper.currentTimeMillis());
					getRawHeaders().put(TIMESTAMP, timestamp);
				}
			}

			this.mutable = false;
		}

		bool isMutable() {
			return this.mutable;
		}

		MessageHeaderAccessor getAccessor() {
			return this.outer;
		}

		protected Object writeReplace() {
			// Serialize as regular MessageHeaders (without MessageHeaderAccessor reference)
			return new MessageHeaders(this);
		}
	}

}
