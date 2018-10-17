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

module hunt.framework.messaging.MessageHeaders;

import hunt.framework.messaging.IdGenerator;

// import hunt.io.ObjectInputStream;
// import hunt.io.ObjectOutputStream;

// import hunt.container.Collection;
// import hunt.container.Collections;
// import hunt.container.HashMap;
// import hunt.container.HashSet;
// import hunt.container.Map;
// import hunt.container.Set;

import hunt.container;
import hunt.datetime;
import hunt.logging;
import hunt.lang.Long;
import hunt.lang.exception;
import hunt.lang.object;

import std.uuid;


/**
 * The headers for a {@link Message}.
 *
 * <p><b>IMPORTANT</b>: This class is immutable. Any mutating operation such as
 * {@code put(..)}, {@code putAll(..)} and others will throw
 * {@link UnsupportedOperationException}.
 * <p>Subclasses do have access to the raw headers, however, via {@link #getRawHeaders()}.
 *
 * <p>One way to create message headers is to use the
 * {@link hunt.framework.messaging.support.MessageBuilder MessageBuilder}:
 * <pre class="code">
 * MessageBuilder.withPayload("foo").setHeader("key1", "value1").setHeader("key2", "value2");
 * </pre>
 *
 * A second option is to create {@link hunt.framework.messaging.support.GenericMessage}
 * passing a payload as {@link Object} and headers as a {@link Map java.util.Map}:
 * <pre class="code">
 * Map headers = new HashMap();
 * headers.put("key1", "value1");
 * headers.put("key2", "value2");
 * new GenericMessage("foo", headers);
 * </pre>
 *
 * A third option is to use {@link hunt.framework.messaging.support.MessageHeaderAccessor}
 * or one of its subclasses to create specific categories of headers.
 *
 * @author Arjen Poutsma
 * @author Mark Fisher
 * @author Gary Russell
 * @author Juergen Hoeller
 * @since 4.0
 * @see hunt.framework.messaging.support.MessageBuilder
 * @see hunt.framework.messaging.support.MessageHeaderAccessor
 */
class MessageHeaders : Map!(string, Object) {

	/**
	 * UUID for none.
	 */
	__gshared static UUID ID_VALUE_NONE;

	/**
	 * The key for the Message ID. This is an automatically generated UUID and
	 * should never be explicitly set in the header map <b>except</b> in the
	 * case of Message deserialization where the serialized Message's generated
	 * UUID is being restored.
	 */
	enum string ID = "id";

	/**
	 * The key for the message timestamp.
	 */
	enum string TIMESTAMP = "timestamp";

	/**
	 * The key for the message content type.
	 */
	enum string CONTENT_TYPE = "contentType";

	/**
	 * The key for the message reply channel.
	 */
	enum string REPLY_CHANNEL = "replyChannel";

	/**
	 * The key for the message error channel.
	 */
	enum string ERROR_CHANNEL = "errorChannel";


	private __gshared static IdGenerator defaultIdGenerator;

	
	private static IdGenerator idGenerator;


	private Map!(string, Object) headers;

	shared static this() {
		ID_VALUE_NONE = UUID.init;
		defaultIdGenerator = new class IdGenerator {
			UUID generateId() {
				return randomUUID();
			}
		};
		// defaultIdGenerator = new AlternativeJdkIdGenerator();
	}


	/**
	 * Construct a {@link MessageHeaders} with the given headers. An {@link #ID} and
	 * {@link #TIMESTAMP} headers will also be added, overriding any existing values.
	 * @param headers a map with headers to add
	 */
	this(Map!(string, Object) headers) {
		this(headers, null, null);
	}

	/**
	 * Constructor providing control over the ID and TIMESTAMP header values.
	 * @param headers a map with headers to add
	 * @param id the {@link #ID} header value
	 * @param timestamp the {@link #TIMESTAMP} header value
	 */
	protected this(Map!(string, Object) headers, UUID* id, Long timestamp) {
		this.headers = (headers !is null ? 
			new HashMap!(string, Object)(headers) 
			: new HashMap!(string, Object)());

		if (id is null) {
			this.headers.put(ID, new Nullable!UUID(randomUUID()));
		}
		else if (*id == ID_VALUE_NONE) {
			this.headers.remove(ID);
		}
		else {
			this.headers.put(ID, new Nullable!UUID(*id));
		}

		if (timestamp is null) {
			timestamp = new Long(DateTimeHelper.currentTimeMillis());
			this.headers.put(TIMESTAMP, timestamp);
		}
		else if (timestamp < 0) {
			this.headers.remove(TIMESTAMP);
		}
		else {
			this.headers.put(TIMESTAMP, timestamp);
		}
	}

	/**
	 * Copy constructor which allows for ignoring certain entries.
	 * Used for serialization without non-serializable entries.
	 * @param original the MessageHeaders to copy
	 * @param keysToIgnore the keys of the entries to ignore
	 */
	private this(MessageHeaders original, Set!(string) keysToIgnore) {
		this.headers = new HashMap!(string, Object)(original.headers.size());
		foreach(string key, Object value; original.headers) {
			if (!keysToIgnore.contains(key))
				this.headers.put(key, value);
		}
	}


	protected Map!(string, Object) getRawHeaders() {
		return this.headers;
	}

	protected static IdGenerator getIdGenerator() {
		IdGenerator generator = idGenerator;
		return (generator !is null ? generator : defaultIdGenerator);
	}

	
	UUID getId() {
		return get!(UUID)(ID);
	}

	
	Long getTimestamp() {
		return get!(Long)(TIMESTAMP);
	}

	
	Object getReplyChannel() {
		return get(REPLY_CHANNEL);
	}

	
	Object getErrorChannel() {
		return get(ERROR_CHANNEL);
	}

	
	T get(T=Object)(string key) {
		Object value = this.headers.get(key);
		if (value is null) {
			return T.init;
		}
		// if (!type.isAssignableFrom(value.getClass())) {
		// 	throw new IllegalArgumentException("Incorrect type specified for header '" ~
		// 			key ~ "'. Expected [" ~ type ~ "] but actual type is [" ~ value.getClass() ~ "]");
		// }
		static if(is(T == Nullable!T)) {
			Nullable!T o = cast(Nullable!T)value;
			return o.payload;
		} else {
			return cast(T) value;
		}
	}


	// Delegating Map implementation

	bool containsKey(Object key) {
		return this.headers.containsKey(key);
	}

	bool containsValue(Object value) {
		return this.headers.containsValue(value);
	}

	// Set<Map.Entry!(string, Object)> entrySet() {
	// 	return Collections.unmodifiableMap(this.headers).entrySet();
	// }

	
	Object get(string key) {
		return this.headers.get(key);
	}

	bool isEmpty() {
		return this.headers.isEmpty();
	}

	// Set!(string) keySet() {
	// 	return Collections.unmodifiableSet(this.headers.keySet());
	// }

	int size() {
		return this.headers.size();
	}

	// Collection!(Object) values() {
	// 	return Collections.unmodifiableCollection(this.headers.values());
	// }


	// Unsupported Map operations

	/**
	 * Since MessageHeaders are immutable, the call to this method
	 * will result in {@link UnsupportedOperationException}.
	 */
	Object put(string key, Object value) {
		throw new UnsupportedOperationException("MessageHeaders is immutable");
	}

	/**
	 * Since MessageHeaders are immutable, the call to this method
	 * will result in {@link UnsupportedOperationException}.
	 */
	void putAll(Map!(string, Object) map) {
		throw new UnsupportedOperationException("MessageHeaders is immutable");
	}

	/**
	 * Since MessageHeaders are immutable, the call to this method
	 * will result in {@link UnsupportedOperationException}.
	 */
	Object remove(string key) {
		throw new UnsupportedOperationException("MessageHeaders is immutable");
	}

	/**
	 * Since MessageHeaders are immutable, the call to this method
	 * will result in {@link UnsupportedOperationException}.
	 */
	void clear() {
		throw new UnsupportedOperationException("MessageHeaders is immutable");
	}


	// Serialization methods

	// private void writeObject(ObjectOutputStream out) throws IOException {
	// 	Set!(string) keysToIgnore = new HashSet<>();
	// 	this.headers.forEach((key, value) -> {
	// 		if (!(value instanceof Serializable)) {
	// 			keysToIgnore.add(key);
	// 		}
	// 	});

	// 	if (keysToIgnore.isEmpty()) {
	// 		// All entries are serializable -> serialize the regular MessageHeaders instance
	// 		out.defaultWriteObject();
	// 	}
	// 	else {
	// 		// Some non-serializable entries -> serialize a temporary MessageHeaders copy
	// 		version(HUNT_DEBUG) {
	// 			trace("Ignoring non-serializable message headers: " ~ keysToIgnore);
	// 		}
	// 		out.writeObject(new MessageHeaders(this, keysToIgnore));
	// 	}
	// }

	// private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
	// 	in.defaultReadObject();
	// }


	// equals, toHash, toString

	override
	bool opEquals(Object other) {
		if(this is other)
			return true;

		MessageHeaders ot = cast(MessageHeaders)other;
		if(ot !is null && this.headers == ot.headers)
			return true;
		return false;
	}

	override
	size_t toHash() @trusted nothrow {
		return this.headers.toHash();
	}

	override
	string toString() {
		return this.headers.toString();
	}

}
