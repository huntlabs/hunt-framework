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

module hunt.framework.messaging.handler.DestinationPatternsMessageCondition;

import hunt.framework.messaging.handler.AbstractMessageCondition;
import hunt.framework.messaging.Message;

import hunt.container;
import hunt.lang.Nullable;
import hunt.string.PathMatcher;

/**
 * A {@link MessageCondition} for matching the destination of a Message
 * against one or more destination patterns using a {@link PathMatcher}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class DestinationPatternsMessageCondition
		: AbstractMessageCondition!(DestinationPatternsMessageCondition, string) {

	/**
	 * The name of the "lookup destination" header.
	 */
	enum string LOOKUP_DESTINATION_HEADER = "lookupDestination";


	private Set!(string) patterns;

	private PathMatcher pathMatcher;


	/**
	 * Creates a new instance with the given destination patterns.
	 * Each pattern that is not empty and does not start with "/" is prepended with "/".
	 * @param patterns 0 or more URL patterns; if 0 the condition will match to every request.
	 */
	this(string[] patterns...) {
		this(patterns, null);
	}

	/**
	 * Alternative constructor accepting a custom PathMatcher.
	 * @param patterns the URL patterns to use; if 0, the condition will match to every request.
	 * @param pathMatcher the PathMatcher to use
	 */
	this(string[] patterns, PathMatcher pathMatcher) {
		this(Arrays.asList(patterns), pathMatcher);
	}

	private this(Collection!(string) patterns, PathMatcher pathMatcher) {
		this.pathMatcher = (pathMatcher !is null ? pathMatcher : new AntPathMatcher());
		this.patterns = Collections.unmodifiableSet(prependLeadingSlash(patterns, this.pathMatcher));
	}


	private static Set!(string) prependLeadingSlash(Collection!(string) patterns, PathMatcher pathMatcher) {
		bool slashSeparator = pathMatcher.combine("a", "a") == ("a/a");
		Set!(string) result = new LinkedHashSet!(string)(patterns.size());
		foreach (string pattern ; patterns) {
			if (slashSeparator && StringUtils.hasLength(pattern) && !pattern.startsWith("/")) {
				pattern = "/" ~ pattern;
			}
			result.add(pattern);
		}
		return result;
	}


	Set!(string) getPatterns() {
		return this.patterns;
	}

	override
	protected Collection!(string) getContent() {
		return this.patterns;
	}

	override
	protected string getToStringInfix() {
		return " || ";
	}


	/**
	 * Returns a new instance with URL patterns from the current instance ("this") and
	 * the "other" instance as follows:
	 * <ul>
	 * <li>If there are patterns in both instances, combine the patterns in "this" with
	 * the patterns in "other" using {@link hunt.framework.util.PathMatcher#combine(string, string)}.
	 * <li>If only one instance has patterns, use them.
	 * <li>If neither instance has patterns, use an empty string (i.e. "").
	 * </ul>
	 */
	// override
	DestinationPatternsMessageCondition combine(DestinationPatternsMessageCondition other) {
		Set!(string) result = new LinkedHashSet!(string)();
		if (!this.patterns.isEmpty() && !other.patterns.isEmpty()) {
			foreach (string pattern1 ; this.patterns) {
				foreach (string pattern2 ; other.patterns) {
					result.add(this.pathMatcher.combine(pattern1, pattern2));
				}
			}
		}
		else if (!this.patterns.isEmpty()) {
			result.addAll(this.patterns);
		}
		else if (!other.patterns.isEmpty()) {
			result.addAll(other.patterns);
		}
		else {
			result.add("");
		}
		return new DestinationPatternsMessageCondition(result, this.pathMatcher);
	}

	/**
	 * Check if any of the patterns match the given Message destination and return an instance
	 * that is guaranteed to contain matching patterns, sorted via
	 * {@link hunt.framework.util.PathMatcher#getPatternComparator(string)}.
	 * @param message the message to match to
	 * @return the same instance if the condition contains no patterns;
	 * or a new condition with sorted matching patterns;
	 * or {@code null} either if a destination can not be extracted or there is no match
	 */
	// override	
	DestinationPatternsMessageCondition getMatchingCondition(MessageBase message) {
		string destination = cast(string)cast(Nullable!string)message.getHeaders().get(LOOKUP_DESTINATION_HEADER);
		if (destination is null) {
			return null;
		}
		if (this.patterns.isEmpty()) {
			return this;
		}

		List!(string) matches = new ArrayList!(string)();
		foreach (string pattern ; this.patterns) {
			if (pattern == destination || this.pathMatcher.match(pattern, destination)) {
				matches.add(pattern);
			}
		}
		if (matches.isEmpty()) {
			return null;
		}

		// TODO: Tasks pending completion -@zxp at 10/31/2018, 10:08:57 AM
		// 
		// matches.sort(this.pathMatcher.getPatternComparator(destination));
		return new DestinationPatternsMessageCondition(matches, this.pathMatcher);
	}

	/**
	 * Compare the two conditions based on the destination patterns they contain.
	 * Patterns are compared one at a time, from top to bottom via
	 * {@link hunt.framework.util.PathMatcher#getPatternComparator(string)}.
	 * If all compared patterns match equally, but one instance has more patterns,
	 * it is considered a closer match.
	 * <p>It is assumed that both instances have been obtained via
	 * {@link #getMatchingCondition(Message)} to ensure they contain only patterns
	 * that match the request and are sorted with the best matches on top.
	 */
	// override
	int compareTo(DestinationPatternsMessageCondition other, MessageBase message) {
		string destination = cast(string)cast(Nullable!string)message.getHeaders().get(LOOKUP_DESTINATION_HEADER);
		if (destination is null) {
			return 0;
		}

// TODO: Tasks pending completion -@zxp at 10/31/2018, 10:09:43 AM
// 
		return 1;

		// Comparator!(string) patternComparator = this.pathMatcher.getPatternComparator(destination);
		// Iterator!(string) iterator = this.patterns.iterator();
		// Iterator!(string) iteratorOther = other.patterns.iterator();
		// while (iterator.hasNext() && iteratorOther.hasNext()) {
		// 	int result = patternComparator.compare(iterator.next(), iteratorOther.next());
		// 	if (result != 0) {
		// 		return result;
		// 	}
		// }

		// if (iterator.hasNext()) {
		// 	return -1;
		// }
		// else if (iteratorOther.hasNext()) {
		// 	return 1;
		// }
		// else {
		// 	return 0;
		// }
	}

}
