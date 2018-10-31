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

module hunt.framework.messaging.handler.AbstractMessageCondition;

import hunt.framework.messaging.handler.MessageCondition;

import hunt.container;
import hunt.string.StringBuilder;



/**
 * Base class for {@code MessageCondition's} that pre-declares abstract methods
 * {@link #getContent()} and {@link #getToStringInfix()} in order to provide
 * implementations of {@link #equals(Object)}, {@link #toHash()}, and
 * {@link #toString()}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param (T) the kind of condition that this condition can be combined with or compared to
 */
abstract class AbstractMessageCondition(T, U) : MessageCondition!(T) {

	override
	bool opEquals(Object other) {
		if (other is null) 
			return false;

		if (this is other) 
			return true;
			
		auto ot = cast(typeof(this)) other;
		if(ot is null)
			return false;
		return getContent() == ot.getContent();
	}

	override
	size_t toHash() @trusted nothrow {
		size_t h = 0;
		try {
			h = getContent().toHash();
		} catch(Exception e) {

		}
		return h;
	}

	override
	string toString() {
		StringBuilder builder = new StringBuilder("[");
		// for (Iterator<?> iterator = getContent().iterator(); iterator.hasNext();) {
		// 	Object expression = iterator.next();
		// 	builder.append(expression.toString());
		// 	if (iterator.hasNext()) {
		// 		builder.append(getToStringInfix());
		// 	}
		// }
		builder.append("]");
		return builder.toString();
	}


	/**
	 * Return the collection of objects the message condition is composed of
	 * (e.g. destination patterns), never {@code null}.
	 */
	protected abstract Collection!U getContent();

	/**
	 * The notation to use when printing discrete items of content.
	 * For example " || " for URL patterns or " && " for param expressions.
	 */
	protected abstract string getToStringInfix();

}
