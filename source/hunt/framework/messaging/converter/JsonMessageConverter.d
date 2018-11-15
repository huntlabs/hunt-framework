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

module hunt.framework.messaging.converter.JsonMessageConverter;

import hunt.framework.messaging.converter.AbstractMessageConverter;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.support.GenericMessage;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.http.codec.http.model.MimeTypes;
import hunt.lang.Charset;
import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.logging;
import hunt.util.TypeUtils;

import std.array;
import std.conv;
import std.json;
import std.string;

/**
*/
class JsonMessageConverter : AbstractMessageConverter {
	
	private bool prettyPrint;

	/**
	 * Construct a {@code JsonMessageConverter} supporting
	 * the {@code application/json} MIME type with {@code UTF-8} character set.
	 */
	this() {
		super(new MimeType("application/json", StandardCharsets.UTF_8));
	}

	/**
	 * Construct a {@code JsonMessageConverter} supporting
	 * one or more custom MIME types.
	 * @param supportedMimeTypes the supported MIME types
	 * @since 4.1.5
	 */
	this(MimeType[] supportedMimeTypes...) {
		super(supportedMimeTypes.dup);
	}

	/**
	 * Whether to use the {@link DefaultPrettyPrinter} when writing JSON.
	 * This is a shortcut for setting up an {@code ObjectMapper} as follows:
	 * <pre class="code">
	 * ObjectMapper mapper = new ObjectMapper();
	 * mapper.configure(SerializationFeature.INDENT_OUTPUT, true);
	 * converter.setObjectMapper(mapper);
	 * </pre>
	 */
	void setPrettyPrint(bool prettyPrint) {
		this.prettyPrint = prettyPrint;
	}


	override
	protected bool canConvertFrom(MessageBase message, TypeInfo targetClass) {
		bool r = true;

		if (targetClass is null || !supportsMimeType(message.getHeaders())) {
			r = false;
		}

		version(HUNT_DEBUG) {
			if(targetClass is null) 
				tracef("checking message, converter: %s, result: %s", 
					TypeUtils.getSimpleName(typeid(this)), r);
			else
				tracef("checking message, target: %s, converter: %s, result: %s", targetClass,
					TypeUtils.getSimpleName(typeid(this)), r);
		} 

		return r;
	}

	override
	protected bool canConvertTo(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		bool r = supportsMimeType(headers);
		version(HUNT_DEBUG) tracef("checking payload, type: %s, converter: %s, result: %s", 
				typeid(payload), TypeUtils.getSimpleName(typeid(this)), r);

		return r;
	}

	override
	protected bool supports(TypeInfo typeInfo) {
		// should not be called, since we override canConvertFrom/canConvertTo instead
		throw new UnsupportedOperationException();
	}

	override
	protected Object convertFromInternal(MessageBase message, TypeInfo targetClass, TypeInfo conversionHint) {
		auto m = cast(GenericMessage!(byte[]))message;
		if(m is null) {
			warningf("Wrong message type: %s", conversionHint);
			return null;
		}
		string payload = cast(string)m.getPayload();
		try {
			JSONValue jv = parseJSON(payload);
			auto r = new Nullable!(JSONValue)(jv);
			return r;
		} catch(Exception ex) {
			errorf("json convertion error: %s", ex.msg);
			infof("message payload: %s", payload);
			throw new MessageConversionException(message, "Could not read JSON: " ~ ex.msg, ex);
		}
	}

	override	
	protected Object convertToInternal(Object payload, MessageHeaders headers,
			TypeInfo conversionHint) {

		auto p = cast(Nullable!(JSONValue))payload;
		if(p is null) {
			warningf("Wrong message type: %s", conversionHint);
			return null;
		}

		JSONValue jv = p.value();
		try {
			string r;
			if(this.prettyPrint)
				r = jv.toPrettyString();
			else
				r = jv.toString();
			return new Nullable!string(r);
		} catch(Exception ex) {
			warning(ex.msg);
			throw new MessageConversionException("Could not write JSON: " ~ ex.msg, ex);
		}
	}
}
