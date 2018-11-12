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

module hunt.framework.messaging.converter.AbstractMessageConverter;

import hunt.framework.messaging.converter.ContentTypeResolver;
import hunt.framework.messaging.converter.DefaultContentTypeResolver;
import hunt.framework.messaging.converter.SmartMessageConverter;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.support.GenericMessage;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.http.codec.http.model.MimeTypes;

import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.logging;
import hunt.container;

import std.array;



/**
 * Abstract base class for {@link SmartMessageConverter} implementations including
 * support for common properties and a partial implementation of the conversion methods,
 * mainly to check if the converter supports the conversion based on the payload class
 * and MIME type.
 *
 * @author Rossen Stoyanchev
 * @author Sebastien Deleuze
 * @author Juergen Hoeller
 * @since 4.0
 */
abstract class AbstractMessageConverter : SmartMessageConverter {

	private MimeType[] supportedMimeTypes;

	private ContentTypeResolver contentTypeResolver;

	private bool strictContentTypeMatch = false;

	// private Class<?> serializedPayloadClass = byte[].class;


	/**
	 * Construct an {@code AbstractMessageConverter} supporting a single MIME type.
	 * @param supportedMimeType the supported MIME type
	 */
	protected this(MimeType supportedMimeType) {
		assert(supportedMimeType, "supportedMimeType is required");
		this.supportedMimeTypes = [supportedMimeType];
		contentTypeResolver = new DefaultContentTypeResolver();
	}

	/**
	 * Construct an {@code AbstractMessageConverter} supporting multiple MIME types.
	 * @param supportedMimeTypes the supported MIME types
	 */
	protected this(MimeType[] supportedMimeTypes) {
		assert(supportedMimeTypes.length>0, "supportedMimeTypes must not be null");
		this.supportedMimeTypes = supportedMimeTypes;
		contentTypeResolver = new DefaultContentTypeResolver();
	}


	/**
	 * Return the supported MIME types.
	 */
	MimeType[] getSupportedMimeTypes() {
		return this.supportedMimeTypes;
	}

	/**
	 * Configure the {@link ContentTypeResolver} to use to resolve the content
	 * type of an input message.
	 * <p>Note that if no resolver is configured, then
	 * {@link #setStrictContentTypeMatch() strictContentTypeMatch} should
	 * be left as {@code false} (the default) or otherwise this converter will
	 * ignore all messages.
	 * <p>By default, a {@code DefaultContentTypeResolver} instance is used.
	 */
	void setContentTypeResolver(ContentTypeResolver resolver) {
		this.contentTypeResolver = resolver;
	}

	/**
	 * Return the configured {@link ContentTypeResolver}.
	 */
	
	ContentTypeResolver getContentTypeResolver() {
		return this.contentTypeResolver;
	}

	/**
	 * Whether this converter should convert messages for which no content type
	 * could be resolved through the configured
	 * {@link hunt.framework.messaging.converter.ContentTypeResolver}.
	 * <p>A converter can configured to be strict only when a
	 * {@link #setContentTypeResolver contentTypeResolver} is configured and the
	 * list of {@link #getSupportedMimeTypes() supportedMimeTypes} is not be empty.
	 * <p>When this flag is set to {@code true}, {@link #supportsMimeType(MessageHeaders)}
	 * will return {@code false} if the {@link #setContentTypeResolver contentTypeResolver}
	 * is not defined or if no content-type header is present.
	 */
	void setStrictContentTypeMatch(bool strictContentTypeMatch) {
		if (strictContentTypeMatch) {
			// assert(getSupportedMimeTypes(), "Strict match requires non-empty list of supported mime types");
			// assert(getContentTypeResolver(), "Strict match requires ContentTypeResolver");
		}
		this.strictContentTypeMatch = strictContentTypeMatch;
	}

	/**
	 * Whether content type resolution must produce a value that matches one of
	 * the supported MIME types.
	 */
	bool isStrictContentTypeMatch() {
		return this.strictContentTypeMatch;
	}

	/**
	 * Configure the preferred serialization class to use (byte[] or string) when
	 * converting an Object payload to a {@link Message}.
	 * <p>The default value is byte[].
	 * @param payloadClass either byte[] or string
	 */
	// void setSerializedPayloadClass(Class<?> payloadClass) {
	// 	assert(byte[].class == payloadClass || string.class == payloadClass,
	// 			() -> "Payload class must be byte[] or string: " ~ payloadClass);
	// 	this.serializedPayloadClass = payloadClass;
	// }

	/**
	 * Return the configured preferred serialization payload class.
	 */
	// Class<?> getSerializedPayloadClass() {
	// 	return this.serializedPayloadClass;
	// }


	/**
	 * Returns the default content type for the payload. Called when
	 * {@link #toMessage(Object, MessageHeaders)} is invoked without message headers or
	 * without a content type header.
	 * <p>By default, this returns the first element of the {@link #getSupportedMimeTypes()
	 * supportedMimeTypes}, if any. Can be overridden in sub-classes.
	 * @param payload the payload being converted to message
	 * @return the content type, or {@code null} if not known
	 */
	
	protected MimeType getDefaultContentType(Object payload) {
		MimeType[] mimeTypes = getSupportedMimeTypes();
		return (mimeTypes.length >0 ? mimeTypes[0] : null);
	}

	// override
	// final Object fromMessage(MessageBase message, Class<?> targetClass) {
	// 	return fromMessage(message, targetClass, null);
	// }

	// override
	// final Object fromMessage(MessageBase message, Class<?> targetClass, Object conversionHint) {
	// 	if (!canConvertFrom(message, targetClass)) {
	// 		return null;
	// 	}
	// 	return convertFromInternal(message, targetClass, conversionHint);
	// }

	protected bool canConvertFrom(MessageBase message, TypeInfo targetClass) {
		return (supports(targetClass) && supportsMimeType(message.getHeaders()));
	}

	override	
	final MessageBase toMessage(Object payload, MessageHeaders headers) {
		return toMessage(payload, headers, null);
	}

	override
	final MessageBase toMessage(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		version(HUNT_DEBUG) trace("converting message...");
		if (!canConvertTo(payload, headers, conversionHint)) {
			version(HUNT_DEBUG) warning("A message can't be converted.");
			return null;
		}
		
		version(HUNT_DEBUG) {
			if(conversionHint !is null)
				tracef("conversionHint: %s", conversionHint);
		}

		Object payloadToUse = convertToInternal(payload, headers, conversionHint);
		if (payloadToUse is null) {
			warningf("Can't convert payload: %s", typeid((cast(Object)payload)));
			return null;
		}

		MimeType mimeType = getDefaultContentType(payloadToUse);
		if (headers !is null) {
			MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!(MessageHeaderAccessor)(headers);
			if (accessor !is null && accessor.isMutable()) {
				if (mimeType !is null) {
					accessor.setHeaderIfAbsent(MessageHeaders.CONTENT_TYPE, mimeType);
				}

				trace("xxxxxxxxx");
				if(conversionHint == typeid(TypeInfo_Class) || conversionHint == typeid(TypeInfo_Interface))
					return MessageHelper.createMessage!(Object)(payloadToUse, accessor.getMessageHeaders());
				else {
					INullable t = cast(INullable)payloadToUse;
					if(t is null)  {
						warningf("Can't handle: %s", typeid((cast(Object)payloadToUse)));
						return null;
					} else {
						// TODO: Tasks pending completion -@zxp at 11/12/2018, 3:02:11 PM
						// handle payload of byte[]
						return new GenericMessage!(string)(payloadToUse.toString(), 
							accessor.getMessageHeaders());
					}
				}
			}
		}

		if(conversionHint == typeid(TypeInfo_Class) || conversionHint == typeid(TypeInfo_Interface)) {
			MessageBuilder!Object builder = MessageHelper.withPayload(payloadToUse);
			if (headers !is null) {
				builder.copyHeaders(headers);
			}
			if (mimeType !is null) {
				builder.setHeaderIfAbsent(MessageHeaders.CONTENT_TYPE, mimeType);
			}
			return builder.build();
		} else {
			INullable t = cast(INullable)payloadToUse;
			if(t is null)  {
				warningf("Can't handle: %s", typeid((cast(Object)payloadToUse)));
				return null;
			} else {
				// TODO: Tasks pending completion -@zxp at 11/12/2018, 3:02:11 PM
				// handle payload of byte[]
				// MessageBuilder!(byte[]) builder = 
				// 	MessageHelper.withPayload!(byte[])(cast(byte[])payloadToUse.toString());
				MessageBuilder!(string) builder = 
					MessageHelper.withPayload!(string)(payloadToUse.toString());
				if (headers !is null) {
					builder.copyHeaders(headers);
				}
				if (mimeType !is null) {
					builder.setHeaderIfAbsent(MessageHeaders.CONTENT_TYPE, mimeType);
				}
				return builder.build();
			}
		}

	}

	protected bool canConvertTo(Object payload, MessageHeaders headers, TypeInfo conversionHint) {
		if(conversionHint !is null) {
			version(HUNT_DEBUG) tracef("raw payload type: %s", conversionHint);
			return (supports(conversionHint) && supportsMimeType(headers));
		} else {
			version(HUNT_DEBUG) tracef("supports: %s, supportsMimeType: %s", 
				supports(typeid(payload)), supportsMimeType(headers));
			return (supports(typeid(payload)) && supportsMimeType(headers));
		}
	}

	protected bool supportsMimeType(MessageHeaders headers) {
		if (getSupportedMimeTypes().empty()) {
			return true;
		}
		MimeType mimeType = getMimeType(headers);
		if (mimeType is null) {
			return !isStrictContentTypeMatch();
		}
		MimeType mimeTypeBaseType = mimeType.getBaseType();
		string mimeTypeName = mimeTypeBaseType.asString();

		foreach (MimeType current ; getSupportedMimeTypes()) {
			MimeType currentBaseType = current.getBaseType();
			// if (current.getType().equals(mimeType.getType()) && current.getSubtype().equals(mimeType.getSubtype())) 
			if(currentBaseType.isSame(mimeTypeName))
				return true;
		}
		return false;
	}

	
	protected MimeType getMimeType(MessageHeaders headers) {
		return (headers !is null && this.contentTypeResolver !is null ? 
			this.contentTypeResolver.resolve(headers) : null);
	}


	/**
	 * Whether the given class is supported by this converter.
	 * @param clazz the class to test for support
	 * @return {@code true} if supported; {@code false} otherwise
	 */
	protected abstract bool supports(TypeInfo typeInfo);

	/**
	 * Convert the message payload from serialized form to an Object.
	 * @param message the input message
	 * @param targetClass the target class for the conversion
	 * @param conversionHint an extra object passed to the {@link MessageConverter},
	 * e.g. the associated {@code MethodParameter} (may be {@code null}}
	 * @return the result of the conversion, or {@code null} if the converter cannot
	 * perform the conversion
	 * @since 4.2
	 */
	
	// protected Object convertFromInternal(
	// 		MessageBase message, Class<?> targetClass, Object conversionHint) {

	// 	return null;
	// }

	/**
	 * Convert the payload object to serialized form.
	 * @param payload the Object to convert
	 * @param headers optional headers for the message (may be {@code null})
	 * @param conversionHint an extra object passed to the {@link MessageConverter},
	 * e.g. the associated {@code MethodParameter} (may be {@code null}}
	 * @return the resulting payload for the message, or {@code null} if the converter
	 * cannot perform the conversion
	 * @since 4.2
	 */
	
	protected Object convertToInternal(
			Object payload, MessageHeaders headers, TypeInfo conversionHint) {
				
		return payload;
	}

}
