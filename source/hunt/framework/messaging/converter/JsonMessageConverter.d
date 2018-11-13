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

// import java.io.ByteArrayOutputStream;
// import java.io.IOException;
// import java.io.StringWriter;
// import java.io.Writer;
// import java.lang.reflect.Type;
// import hunt.lang.Charset;

// import java.util.Arrays;
// import java.util.concurrent.atomic.AtomicReference;

// import com.fasterxml.jackson.annotation.JsonView;
// import com.fasterxml.jackson.core.JsonEncoding;
// import com.fasterxml.jackson.core.JsonGenerator;
// import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
// import com.fasterxml.jackson.databind.DeserializationFeature;
// import com.fasterxml.jackson.databind.JavaType;
// import com.fasterxml.jackson.databind.JsonMappingException;
// import com.fasterxml.jackson.databind.MapperFeature;
// import com.fasterxml.jackson.databind.ObjectMapper;
// import com.fasterxml.jackson.databind.SerializationFeature;

// import hunt.framework.core.GenericTypeResolver;
// import hunt.framework.core.MethodParameter;

import hunt.framework.messaging.converter.AbstractMessageConverter;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.support.GenericMessage;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.http.codec.http.model.MimeTypes;
import hunt.lang.Charset;
import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.logging;

import std.array;
import std.conv;
import std.format;
import std.json;
import std.string;

/**
*/
class JsonMessageConverter : AbstractMessageConverter {

	// private ObjectMapper objectMapper;

	// private JSONValue objectMapper;
	
	private bool prettyPrint;


	/**
	 * Construct a {@code JsonMessageConverter} supporting
	 * the {@code application/json} MIME type with {@code UTF-8} character set.
	 */
	this() {
		super(new MimeType("application/json", StandardCharsets.UTF_8));
		// this.objectMapper = initObjectMapper();
	}

	/**
	 * Construct a {@code JsonMessageConverter} supporting
	 * one or more custom MIME types.
	 * @param supportedMimeTypes the supported MIME types
	 * @since 4.1.5
	 */
	this(MimeType[] supportedMimeTypes...) {
		super(supportedMimeTypes.dup);
		// this.objectMapper = initObjectMapper();
	}


	// private ObjectMapper initObjectMapper() {
	// 	ObjectMapper objectMapper = new ObjectMapper();
	// 	objectMapper.configure(MapperFeature.DEFAULT_VIEW_INCLUSION, false);
	// 	objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
	// 	return objectMapper;
	// }

	/**
	 * Set the {@code ObjectMapper} for this converter.
	 * If not set, a default {@link ObjectMapper#ObjectMapper() ObjectMapper} is used.
	 * <p>Setting a custom-configured {@code ObjectMapper} is one way to take further
	 * control of the JSON serialization process. For example, an extended
	 * {@link com.fasterxml.jackson.databind.ser.SerializerFactory} can be
	 * configured that provides custom serializers for specific types. The other
	 * option for refining the serialization process is to use Jackson's provided
	 * annotations on the types to be serialized, in which case a custom-configured
	 * ObjectMapper is unnecessary.
	 */
	// void setObjectMapper(ObjectMapper objectMapper) {
	// 	assert(objectMapper, "ObjectMapper must not be null");
	// 	this.objectMapper = objectMapper;
	// 	configurePrettyPrint();
	// }

	/**
	 * Return the underlying {@code ObjectMapper} for this converter.
	 */
	// ObjectMapper getObjectMapper() {
	// 	return this.objectMapper;
	// }

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
		// configurePrettyPrint();
	}

	// private void configurePrettyPrint() {
	// 	if (this.prettyPrint !is null) {
	// 		this.objectMapper.configure(SerializationFeature.INDENT_OUTPUT, this.prettyPrint);
	// 	}
	// }

	override
	protected bool canConvertFrom(MessageBase message, TypeInfo targetClass) {
		if (targetClass is null || !supportsMimeType(message.getHeaders())) {
			return false;
		}
		return true;
	}

	override
	protected bool canConvertTo(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		if (!supportsMimeType(headers)) {
			return false;
		}
		return true;
	}

	/**
	 * Determine whether to log the given exception coming from a
	 * {@link ObjectMapper#canDeserialize} / {@link ObjectMapper#canSerialize} check.
	 * @param type the class that Jackson tested for (de-)serializability
	 * @param cause the Jackson-thrown exception to evaluate
	 * (typically a {@link JsonMappingException})
	 * @since 4.3
	 */
	// protected void logWarningIfNecessary(Type type, Throwable cause) {
	// 	if (cause is null) {
	// 		return;
	// 	}

	// 	// Do not log warning for serializer not found (note: different message wording on Jackson 2.9)
	// 	 debugLevel = (cause instanceof JsonMappingException && cause.getMessage().startsWith("Cannot find"));

	// 	if (debugLevel ? logger.isDebugEnabled() : logger.isWarnEnabled()) {
	// 		string msg = "Failed to evaluate Jackson " ~ (type instanceof JavaType ? "de" : "") +
	// 				"serialization for type [" ~ type ~ "]";
	// 		if (debugLevel) {
	// 			trace(msg, cause);
	// 		}
	// 		else version(HUNT_DEBUG) {
	// 			warningf(msg, cause);
	// 		}
	// 		else {
	// 			warningf(msg ~ ": " ~ cause);
	// 		}
	// 	}
	// }

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

		warning("ddddddddddddddddddd");
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
