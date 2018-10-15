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

module hunt.framework.messaging.support.AbstractHeaderMapper;

import hunt.framework.messaging.MessageHeaders;
import hunt.container.Map;
import hunt.logging;


/**
 * A base {@link HeaderMapper} implementation.
 *
 * @author Stephane Nicoll
 * @since 4.1
 * @param (T) type of the instance to and from which headers will be mapped
 */
abstract class AbstractHeaderMapper(T) : HeaderMapper!(T) {

	private string inboundPrefix = "";

	private string outboundPrefix = "";


	/**
	 * Specify a prefix to be appended to the message header name for any
	 * user-defined property that is being mapped into the MessageHeaders.
	 * The default is an empty string (no prefix).
	 */
	void setInboundPrefix(string inboundPrefix) {
		this.inboundPrefix = (inboundPrefix !is null ? inboundPrefix : "");
	}

	/**
	 * Specify a prefix to be appended to the protocol property name for any
	 * user-defined message header that is being mapped into the protocol-specific
	 * Message. The default is an empty string (no prefix).
	 */
	void setOutboundPrefix(string outboundPrefix) {
		this.outboundPrefix = (outboundPrefix !is null ? outboundPrefix : "");
	}


	/**
	 * Generate the name to use to set the header defined by the specified
	 * {@code headerName} to the protocol specific message.
	 * @see #setOutboundPrefix
	 */
	protected string fromHeaderName(string headerName) {
		string propertyName = headerName;
		if (StringUtils.hasText(this.outboundPrefix) && !propertyName.startsWith(this.outboundPrefix)) {
			propertyName = this.outboundPrefix + headerName;
		}
		return propertyName;
	}

	/**
	 * Generate the name to use to set the header defined by the specified
	 * {@code propertyName} to the {@link MessageHeaders} instance.
	 * @see #setInboundPrefix(string)
	 */
	protected string toHeaderName(string propertyName) {
		string headerName = propertyName;
		if (StringUtils.hasText(this.inboundPrefix) && !headerName.startsWith(this.inboundPrefix)) {
			headerName = this.inboundPrefix + propertyName;
		}
		return headerName;
	}

	/**
	 * Return the header value, or {@code null} if it does not exist
	 * or does not match the requested {@code type}.
	 */
	
	protected V getHeaderIfAvailable(V)(Map!(string, Object) headers, string name) {
		Object value = headers.get(name);
		if (value is null) {
			return V.init;
		}

		static if(is(T == Nullable!T)) {
			Nullable!T o = cast(Nullable!T)value;
			return o.value;
		} else {
			return cast(T) value;
		}

		// if (!type.isAssignableFrom(value.getClass())) {
		// 	version(HUNT_DEBUG) {
		// 		trace("Skipping header '" ~ name ~ "': expected type [" ~ type ~ "], but got [" ~
		// 				value.getClass() ~ "]");
		// 	}
		// 	return null;
		// }
		// else {
		// 	return type.cast(value);
		// }
	}

}
