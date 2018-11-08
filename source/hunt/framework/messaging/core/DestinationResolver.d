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

module hunt.framework.messaging.core.DestinationResolver;

/**
 * Strategy for resolving a string destination name to an actual destination
 * of type {@code !(T)}.
 *
 * @author Mark Fisher
 * @since 4.0
 * @param (T) the destination type
 */

interface DestinationResolver(T) {

	/**
	 * Resolve the given destination name.
	 * @param name the destination name to resolve
	 * @return the resolved destination (never {@code null})
	 * @throws DestinationResolutionException if the specified destination
	 * wasn't found or wasn't resolvable for any other reason
	 */
	T resolveDestination(string name);

}
