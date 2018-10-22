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

module hunt.framework.messaging.converter.SmartMessageConverter;

import hunt.framework.messaging.converter.MessageConverter;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;

/**
 * An extended {@link MessageConverter} SPI with conversion hint support.
 *
 * <p>In case of a conversion hint being provided, the framework will call
 * these extended methods if a converter implements this interface, instead
 * of calling the regular {@code fromMessage} / {@code toMessage} variants.
 *
 * @author Juergen Hoeller
 * @since 4.2.1
 */
interface SmartMessageConverter(T) : MessageConverter!(T) {

	/**
	 * A variant of {@link #fromMessage(Message, Class)} which takes an extra
	 * conversion context as an argument, allowing to take e.g. annotations
	 * on a payload parameter into account.
	 * @param message the input message
	 * @param targetClass the target class for the conversion
	 * @param conversionHint an extra object passed to the {@link MessageConverter},
	 * e.g. the associated {@code MethodParameter} (may be {@code null}}
	 * @return the result of the conversion, or {@code null} if the converter cannot
	 * perform the conversion
	 * @see #fromMessage(Message, Class)
	 */
	
	// Object fromMessage(MessageBase message, Class!(T) targetClass, Object conversionHint);

	/**
	 * A variant of {@link #toMessage(Object, MessageHeaders)} which takes an extra
	 * conversion context as an argument, allowing to take e.g. annotations
	 * on a return type into account.
	 * @param payload the Object to convert
	 * @param headers optional headers for the message (may be {@code null})
	 * @param conversionHint an extra object passed to the {@link MessageConverter},
	 * e.g. the associated {@code MethodParameter} (may be {@code null}}
	 * @return the new message, or {@code null} if the converter does not support the
	 * Object type or the target media type
	 * @see #toMessage(Object, MessageHeaders)
	 */
	
	Message!(T) toMessage(Object payload, MessageHeaders headers, Object conversionHint);

}
