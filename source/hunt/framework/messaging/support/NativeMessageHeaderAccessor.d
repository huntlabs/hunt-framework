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

module hunt.framework.messaging.support.NativeMessageHeaderAccessor;

import hunt.container.Collections;
import java.util.LinkedList;
import java.util.List;
import hunt.container.Map;


import hunt.framework.messaging.Message;
import org.springframework.util.Assert;
import org.springframework.util.CollectionUtils;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.ObjectUtils;

/**
 * An extension of {@link MessageHeaderAccessor} that also stores and provides read/write
 * access to message headers from an external source -- e.g. a Spring {@link Message}
 * created to represent a STOMP message received from a STOMP client or message broker.
 * Native message headers are kept in a {@code Map<string, List!(string)>} under the key
 * {@link #NATIVE_HEADERS}.
 *
 * <p>This class is not intended for direct use but is rather expected to be used
 * indirectly through protocol-specific sub-classes such as
 * {@link hunt.framework.messaging.simp.stomp.StompHeaderAccessor StompHeaderAccessor}.
 * Such sub-classes may provide factory methods to translate message headers from
 * an external messaging source (e.g. STOMP) to Spring {@link Message} headers and
 * reversely to translate Spring {@link Message} headers to a message to send to an
 * external source.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class NativeMessageHeaderAccessor : MessageHeaderAccessor {

	/**
	 * The header name used to store native headers.
	 */
	static final string NATIVE_HEADERS = "nativeHeaders";


	/**
	 * A protected constructor to create new headers.
	 */
	protected NativeMessageHeaderAccessor() {
		this((Map<string, List!(string)>) null);
	}

	/**
	 * A protected constructor to create new headers.
	 * @param nativeHeaders native headers to create the message with (may be {@code null})
	 */
	protected NativeMessageHeaderAccessor(Map<string, List!(string)> nativeHeaders) {
		if (!CollectionUtils.isEmpty(nativeHeaders)) {
			setHeader(NATIVE_HEADERS, new LinkedMultiValueMap<>(nativeHeaders));
		}
	}

	/**
	 * A protected constructor accepting the headers of an existing message to copy.
	 */
	protected NativeMessageHeaderAccessor(Message<?> message) {
		super(message);
		if (message !is null) {
			
			Map<string, List!(string)> map = (Map<string, List!(string)>) getHeader(NATIVE_HEADERS);
			if (map !is null) {
				// Force removal since setHeader checks for equality
				removeHeader(NATIVE_HEADERS);
				setHeader(NATIVE_HEADERS, new LinkedMultiValueMap<>(map));
			}
		}
	}

	
	
	protected Map<string, List!(string)> getNativeHeaders() {
		return (Map<string, List!(string)>) getHeader(NATIVE_HEADERS);
	}

	/**
	 * Return a copy of the native header values or an empty map.
	 */
	Map<string, List!(string)> toNativeHeaderMap() {
		Map<string, List!(string)> map = getNativeHeaders();
		return (map !is null ? new LinkedMultiValueMap<>(map) : Collections.emptyMap());
	}

	override
	void setImmutable() {
		if (isMutable()) {
			Map<string, List!(string)> map = getNativeHeaders();
			if (map !is null) {
				// Force removal since setHeader checks for equality
				removeHeader(NATIVE_HEADERS);
				setHeader(NATIVE_HEADERS, Collections.unmodifiableMap(map));
			}
			super.setImmutable();
		}
	}

	/**
	 * Whether the native header map contains the give header name.
	 */
	 containsNativeHeader(string headerName) {
		Map<string, List!(string)> map = getNativeHeaders();
		return (map !is null && map.containsKey(headerName));
	}

	/**
	 * Return all values for the specified native header.
	 * or {@code null} if none.
	 */
	
	List!(string) getNativeHeader(string headerName) {
		Map<string, List!(string)> map = getNativeHeaders();
		return (map !is null ? map.get(headerName) : null);
	}

	/**
	 * Return the first value for the specified native header,
	 * or {@code null} if none.
	 */
	
	string getFirstNativeHeader(string headerName) {
		Map<string, List!(string)> map = getNativeHeaders();
		if (map !is null) {
			List!(string) values = map.get(headerName);
			if (values !is null) {
				return values.get(0);
			}
		}
		return null;
	}

	/**
	 * Set the specified native header value replacing existing values.
	 */
	void setNativeHeader(string name, string value) {
		Assert.state(isMutable(), "Already immutable");
		Map<string, List!(string)> map = getNativeHeaders();
		if (value is null) {
			if (map !is null && map.get(name) !is null) {
				setModified(true);
				map.remove(name);
			}
			return;
		}
		if (map is null) {
			map = new LinkedMultiValueMap<>(4);
			setHeader(NATIVE_HEADERS, map);
		}
		List!(string) values = new LinkedList<>();
		values.add(value);
		if (!ObjectUtils.nullSafeEquals(values, getHeader(name))) {
			setModified(true);
			map.put(name, values);
		}
	}

	/**
	 * Add the specified native header value to existing values.
	 */
	void addNativeHeader(string name, string value) {
		Assert.state(isMutable(), "Already immutable");
		if (value is null) {
			return;
		}
		Map<string, List!(string)> nativeHeaders = getNativeHeaders();
		if (nativeHeaders is null) {
			nativeHeaders = new LinkedMultiValueMap<>(4);
			setHeader(NATIVE_HEADERS, nativeHeaders);
		}
		List!(string) values = nativeHeaders.computeIfAbsent(name, k -> new LinkedList<>());
		values.add(value);
		setModified(true);
	}

	void addNativeHeaders(MultiValueMap<string, string> headers) {
		if (headers is null) {
			return;
		}
		headers.forEach((key, values) -> values.forEach(value -> addNativeHeader(key, value)));
	}

	
	List!(string) removeNativeHeader(string name) {
		Assert.state(isMutable(), "Already immutable");
		Map<string, List!(string)> nativeHeaders = getNativeHeaders();
		if (nativeHeaders is null) {
			return null;
		}
		return nativeHeaders.remove(name);
	}

	
	
	static string getFirstNativeHeader(string headerName, Map!(string, Object) headers) {
		Map<string, List!(string)> map = (Map<string, List!(string)>) headers.get(NATIVE_HEADERS);
		if (map !is null) {
			List!(string) values = map.get(headerName);
			if (values !is null) {
				return values.get(0);
			}
		}
		return null;
	}

}
