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

module hunt.framework.messaging.converter.DefaultContentTypeResolver;

import hunt.framework.messaging.converter.ContentTypeResolver;
import hunt.framework.messaging.MessageHeaders;
import hunt.http.codec.http.model.MimeTypes;

import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.lang.String;

/**
 * A default {@link ContentTypeResolver} that checks the
 * {@link MessageHeaders#CONTENT_TYPE} header or falls back to a default value.
 *
 * <p>The header value is expected to be a {@link hunt.framework.util.MimeType}
 * or a {@code string} that can be parsed into a {@code MimeType}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class DefaultContentTypeResolver : ContentTypeResolver {

	private MimeType defaultMimeType;


	/**
	 * Set the default MIME type to use when there is no
	 * {@link MessageHeaders#CONTENT_TYPE} header present.
	 * <p>This property does not have a default value.
	 */
	void setDefaultMimeType(MimeType defaultMimeType) {
		this.defaultMimeType = defaultMimeType;
	}

	/**
	 * Return the default MIME type to use if no
	 * {@link MessageHeaders#CONTENT_TYPE} header is present.
	 */
	
	MimeType getDefaultMimeType() {
		return this.defaultMimeType;
	}


	override
	
	MimeType resolve(MessageHeaders headers) {
		if (headers is null || headers.get(MessageHeaders.CONTENT_TYPE) is null) {
			return this.defaultMimeType;
		}
		
		Object value = headers.get(MessageHeaders.CONTENT_TYPE);
		if (value is null) {
			return null;
		}

		MimeType mt = cast(MimeType) value;
		if (mt !is null) {
			return mt;
		}

		String strObject = cast(String)value;
		if (strObject !is null) {
			return new MimeType(strObject.value);
		}
		
		throw new IllegalArgumentException(
				"Unknown type for contentType header value: " ~ typeid(value).toString());
	}

	override
	string toString() {
		return "DefaultContentTypeResolver[" ~ "defaultMimeType=" ~ 
			this.defaultMimeType.toString() ~ "]";
	}

}
