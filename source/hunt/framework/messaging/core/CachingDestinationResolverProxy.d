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

module hunt.framework.messaging.core.CachingDestinationResolverProxy;

import hunt.container.Map;
// import java.util.concurrent.ConcurrentHashMap;

// import hunt.framework.beans.factory.InitializingBean;



/**
 * {@link DestinationResolver} implementation that proxies a target DestinationResolver,
 * caching its {@link #resolveDestination} results. Such caching is particularly useful
 * if the destination resolving process is expensive (e.g. the destination has to be
 * resolved through an external system) and the resolution results are stable anyway.
 *
 * @author Agim Emruli
 * @author Juergen Hoeller
 * @since 4.1
 * @param (T) the destination type
 * @see DestinationResolver#resolveDestination
 */
class CachingDestinationResolverProxy(T) : DestinationResolver!(T) { // , InitializingBean

	// private final Map!(string, T) resolvedDestinationCache = new ConcurrentHashMap<>();

	
	// private DestinationResolver!(T) targetDestinationResolver;


	// /**
	//  * Create a new CachingDestinationResolverProxy, setting the target DestinationResolver
	//  * through the {@link #setTargetDestinationResolver} bean property.
	//  */
	// this() {
	// }

	// /**
	//  * Create a new CachingDestinationResolverProxy using the given target
	//  * DestinationResolver to actually resolve destinations.
	//  * @param targetDestinationResolver the target DestinationResolver to delegate to
	//  */
	// this(DestinationResolver!(T) targetDestinationResolver) {
	// 	assert(targetDestinationResolver, "Target DestinationResolver must not be null");
	// 	this.targetDestinationResolver = targetDestinationResolver;
	// }


	// /**
	//  * Set the target DestinationResolver to delegate to.
	//  */
	// void setTargetDestinationResolver(DestinationResolver!(T) targetDestinationResolver) {
	// 	this.targetDestinationResolver = targetDestinationResolver;
	// }

	// override
	// void afterPropertiesSet() {
	// 	if (this.targetDestinationResolver is null) {
	// 		throw new IllegalArgumentException("Property 'targetDestinationResolver' is required");
	// 	}
	// }


	// /**
	//  * Resolves and caches destinations if successfully resolved by the target
	//  * DestinationResolver implementation.
	//  * @param name the destination name to be resolved
	//  * @return the currently resolved destination or an already cached destination
	//  * @throws DestinationResolutionException if the target DestinationResolver
	//  * reports an error during destination resolution
	//  */
	// override
	// T resolveDestination(string name) throws DestinationResolutionException {
	// 	T destination = this.resolvedDestinationCache.get(name);
	// 	if (destination is null) {
	// 		assert(this.targetDestinationResolver !is null, "No target DestinationResolver set");
	// 		destination = this.targetDestinationResolver.resolveDestination(name);
	// 		this.resolvedDestinationCache.put(name, destination);
	// 	}
	// 	return destination;
	// }

}
