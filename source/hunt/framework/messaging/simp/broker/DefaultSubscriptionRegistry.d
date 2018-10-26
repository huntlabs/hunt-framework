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

module hunt.framework.messaging.simp.broker.DefaultSubscriptionRegistry;

import hunt.container;
// import java.util.concurrent.ConcurrentHashMap;
// import java.util.concurrent.ConcurrentMap;
// import java.util.concurrent.CopyOnWriteArraySet;

// import hunt.framework.expression.EvaluationContext;
// import hunt.framework.expression.Expression;
// import hunt.framework.expression.ExpressionParser;
// import hunt.framework.expression.PropertyAccessor;
// import hunt.framework.expression.TypedValue;
// import hunt.framework.expression.spel.SpelEvaluationException;
// import hunt.framework.expression.spel.standard.SpelExpressionParser;
// import hunt.framework.expression.spel.support.SimpleEvaluationContext;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.support.MessageHeaderAccessor;
// import hunt.framework.util.AntPathMatcher;

// import hunt.framework.util.LinkedMultiValueMap;
// import hunt.framework.util.MultiValueMap;
// import hunt.framework.util.PathMatcher;
// import hunt.framework.util.StringUtils;

/**
 * Implementation of {@link SubscriptionRegistry} that stores subscriptions
 * in memory and uses a {@link hunt.framework.util.PathMatcher PathMatcher}
 * for matching destinations.
 *
 * <p>As of 4.2, this class supports a {@link #setSelectorHeaderName selector}
 * header on subscription messages with Spring EL expressions evaluated against
 * the headers to filter out messages in addition to destination matching.
 *
 * @author Rossen Stoyanchev
 * @author Sebastien Deleuze
 * @author Juergen Hoeller
 * @since 4.0
 */
// class DefaultSubscriptionRegistry : AbstractSubscriptionRegistry {

// 	/** Default maximum number of entries for the destination cache: 1024. */
// 	enum int DEFAULT_CACHE_LIMIT = 1024;

// 	/** Static evaluation context to reuse. */
// 	private static EvaluationContext messageEvalContext =
// 			SimpleEvaluationContext.forPropertyAccessors(new SimpMessageHeaderPropertyAccessor()).build();


// 	private PathMatcher pathMatcher = new AntPathMatcher();

// 	private int cacheLimit = DEFAULT_CACHE_LIMIT;

	
// 	private string selectorHeaderName = "selector";

// 	private bool selectorHeaderInUse = false;

// 	private final ExpressionParser expressionParser = new SpelExpressionParser();

// 	private final DestinationCache destinationCache = new DestinationCache();

// 	private final SessionSubscriptionRegistry subscriptionRegistry = new SessionSubscriptionRegistry();


// 	/**
// 	 * Specify the {@link PathMatcher} to use.
// 	 */
// 	void setPathMatcher(PathMatcher pathMatcher) {
// 		this.pathMatcher = pathMatcher;
// 	}

// 	/**
// 	 * Return the configured {@link PathMatcher}.
// 	 */
// 	PathMatcher getPathMatcher() {
// 		return this.pathMatcher;
// 	}

// 	/**
// 	 * Specify the maximum number of entries for the resolved destination cache.
// 	 * Default is 1024.
// 	 */
// 	void setCacheLimit(int cacheLimit) {
// 		this.cacheLimit = cacheLimit;
// 	}

// 	/**
// 	 * Return the maximum number of entries for the resolved destination cache.
// 	 */
// 	int getCacheLimit() {
// 		return this.cacheLimit;
// 	}

// 	/**
// 	 * Configure the name of a header that a subscription message can have for
// 	 * the purpose of filtering messages matched to the subscription. The header
// 	 * value is expected to be a Spring EL  expression to be applied to
// 	 * the headers of messages matched to the subscription.
// 	 * <p>For example:
// 	 * <pre>
// 	 * headers.foo == 'bar'
// 	 * </pre>
// 	 * <p>By default this is set to "selector". You can set it to a different
// 	 * name, or to {@code null} to turn off support for a selector header.
// 	 * @param selectorHeaderName the name to use for a selector header
// 	 * @since 4.2
// 	 */
// 	void setSelectorHeaderName(string selectorHeaderName) {
// 		this.selectorHeaderName = StringUtils.hasText(selectorHeaderName) ? selectorHeaderName : null;
// 	}

// 	/**
// 	 * Return the name for the selector header name.
// 	 * @since 4.2
// 	 */
	
// 	string getSelectorHeaderName() {
// 		return this.selectorHeaderName;
// 	}


// 	override
// 	protected void addSubscriptionInternal(
// 			string sessionId, string subsId, string destination, MessageBase message) {

// 		Expression expression = getSelectorExpression(message.getHeaders());
// 		this.subscriptionRegistry.addSubscription(sessionId, subsId, destination, expression);
// 		this.destinationCache.updateAfterNewSubscription(destination, sessionId, subsId);
// 	}

	
// 	private Expression getSelectorExpression(MessageHeaders headers) {
// 		Expression expression = null;
// 		if (getSelectorHeaderName() !is null) {
// 			string selector = SimpMessageHeaderAccessor.getFirstNativeHeader(getSelectorHeaderName(), headers);
// 			if (selector !is null) {
// 				try {
// 					expression = this.expressionParser.parseExpression(selector);
// 					this.selectorHeaderInUse = true;
// 					version(HUNT_DEBUG) {
// 						trace("Subscription selector: [" ~ selector ~ "]");
// 					}
// 				}
// 				catch (Throwable ex) {
// 					version(HUNT_DEBUG) {
// 						trace("Failed to parse selector: " ~ selector, ex);
// 					}
// 				}
// 			}
// 		}
// 		return expression;
// 	}

// 	override
// 	protected void removeSubscriptionInternal(string sessionId, string subsId, MessageBase message) {
// 		SessionSubscriptionInfo info = this.subscriptionRegistry.getSubscriptions(sessionId);
// 		if (info !is null) {
// 			string destination = info.removeSubscription(subsId);
// 			if (destination !is null) {
// 				this.destinationCache.updateAfterRemovedSubscription(sessionId, subsId);
// 			}
// 		}
// 	}

// 	override
// 	void unregisterAllSubscriptions(string sessionId) {
// 		SessionSubscriptionInfo info = this.subscriptionRegistry.removeSubscriptions(sessionId);
// 		if (info !is null) {
// 			this.destinationCache.updateAfterRemovedSession(info);
// 		}
// 	}

// 	override
// 	protected MultiValueMap!(string, string) findSubscriptionsInternal(string destination, MessageBase message) {
// 		MultiValueMap!(string, string) result = this.destinationCache.getSubscriptions(destination, message);
// 		return filterSubscriptions(result, message);
// 	}

// 	private MultiValueMap!(string, string) filterSubscriptions(
// 			MultiValueMap!(string, string) allMatches, MessageBase message) {

// 		if (!this.selectorHeaderInUse) {
// 			return allMatches;
// 		}
// 		MultiValueMap!(string, string) result = new LinkedMultiValueMap<>(allMatches.size());
// 		allMatches.forEach((sessionId, subIds) -> {
// 			for (string subId : subIds) {
// 				SessionSubscriptionInfo info = this.subscriptionRegistry.getSubscriptions(sessionId);
// 				if (info is null) {
// 					continue;
// 				}
// 				Subscription sub = info.getSubscription(subId);
// 				if (sub is null) {
// 					continue;
// 				}
// 				Expression expression = sub.getSelectorExpression();
// 				if (expression is null) {
// 					result.add(sessionId, subId);
// 					continue;
// 				}
// 				try {
// 					if (Boolean.TRUE.equals(expression.getValue(messageEvalContext, message, Boolean.class))) {
// 						result.add(sessionId, subId);
// 					}
// 				}
// 				catch (SpelEvaluationException ex) {
// 					version(HUNT_DEBUG) {
// 						trace("Failed to evaluate selector: " ~ ex.getMessage());
// 					}
// 				}
// 				catch (Throwable ex) {
// 					trace("Failed to evaluate selector", ex);
// 				}
// 			}
// 		});
// 		return result;
// 	}

// 	override
// 	string toString() {
// 		return "DefaultSubscriptionRegistry[" ~ this.destinationCache ~ ", " ~ this.subscriptionRegistry ~ "]";
// 	}


// 	/**
// 	 * A cache for destinations previously resolved via
// 	 * {@link DefaultSubscriptionRegistry#findSubscriptionsInternal(string, Message)}.
// 	 */
// 	private class DestinationCache {

// 		/** Map from destination to {@code <sessionId, subscriptionId>} for fast look-ups. */
// 		private final Map!(string, LinkedMultiValueMap!(string, string)) accessCache =
// 				new ConcurrentHashMap<>(DEFAULT_CACHE_LIMIT);

// 		/** Map from destination to {@code <sessionId, subscriptionId>} with locking. */
		
// 		private final Map!(string, LinkedMultiValueMap!(string, string)) updateCache =
// 				new LinkedHashMap!(string, LinkedMultiValueMap!(string, string))(DEFAULT_CACHE_LIMIT, 0.75f, true) {
// 					override
// 					protected bool removeEldestEntry(Map.Entry!(string, LinkedMultiValueMap!(string, string)) eldest) {
// 						if (size() > getCacheLimit()) {
// 							accessCache.remove(eldest.getKey());
// 							return true;
// 						}
// 						else {
// 							return false;
// 						}
// 					}
// 				};


// 		LinkedMultiValueMap!(string, string) getSubscriptions(string destination, MessageBase message) {
// 			LinkedMultiValueMap!(string, string) result = this.accessCache.get(destination);
// 			if (result is null) {
// 				synchronized (this.updateCache) {
// 					result = new LinkedMultiValueMap<>();
// 					for (SessionSubscriptionInfo info : subscriptionRegistry.getAllSubscriptions()) {
// 						for (string destinationPattern : info.getDestinations()) {
// 							if (getPathMatcher().match(destinationPattern, destination)) {
// 								for (Subscription sub : info.getSubscriptions(destinationPattern)) {
// 									result.add(info.sessionId, sub.getId());
// 								}
// 							}
// 						}
// 					}
// 					if (!result.isEmpty()) {
// 						this.updateCache.put(destination, result.deepCopy());
// 						this.accessCache.put(destination, result);
// 					}
// 				}
// 			}
// 			return result;
// 		}

// 		void updateAfterNewSubscription(string destination, string sessionId, string subsId) {
// 			synchronized (this.updateCache) {
// 				this.updateCache.forEach((cachedDestination, subscriptions) -> {
// 					if (getPathMatcher().match(destination, cachedDestination)) {
// 						// Subscription id's may also be populated via getSubscriptions()
// 						List!(string) subsForSession = subscriptions.get(sessionId);
// 						if (subsForSession is null || !subsForSession.contains(subsId)) {
// 							subscriptions.add(sessionId, subsId);
// 							this.accessCache.put(cachedDestination, subscriptions.deepCopy());
// 						}
// 					}
// 				});
// 			}
// 		}

// 		void updateAfterRemovedSubscription(string sessionId, string subsId) {
// 			synchronized (this.updateCache) {
// 				Set!(string) destinationsToRemove = new HashSet<>();
// 				this.updateCache.forEach((destination, sessionMap) -> {
// 					List!(string) subscriptions = sessionMap.get(sessionId);
// 					if (subscriptions !is null) {
// 						subscriptions.remove(subsId);
// 						if (subscriptions.isEmpty()) {
// 							sessionMap.remove(sessionId);
// 						}
// 						if (sessionMap.isEmpty()) {
// 							destinationsToRemove.add(destination);
// 						}
// 						else {
// 							this.accessCache.put(destination, sessionMap.deepCopy());
// 						}
// 					}
// 				});
// 				for (string destination : destinationsToRemove) {
// 					this.updateCache.remove(destination);
// 					this.accessCache.remove(destination);
// 				}
// 			}
// 		}

// 		void updateAfterRemovedSession(SessionSubscriptionInfo info) {
// 			synchronized (this.updateCache) {
// 				Set!(string) destinationsToRemove = new HashSet<>();
// 				this.updateCache.forEach((destination, sessionMap) -> {
// 					if (sessionMap.remove(info.getSessionId()) !is null) {
// 						if (sessionMap.isEmpty()) {
// 							destinationsToRemove.add(destination);
// 						}
// 						else {
// 							this.accessCache.put(destination, sessionMap.deepCopy());
// 						}
// 					}
// 				});
// 				for (string destination : destinationsToRemove) {
// 					this.updateCache.remove(destination);
// 					this.accessCache.remove(destination);
// 				}
// 			}
// 		}

// 		override
// 		string toString() {
// 			return "cache[" ~ this.accessCache.size() ~ " destination(s)]";
// 		}
// 	}


// 	/**
// 	 * Provide access to session subscriptions by sessionId.
// 	 */
// 	private static class SessionSubscriptionRegistry {

// 		// sessionId -> SessionSubscriptionInfo
// 		private final ConcurrentMap!(string, SessionSubscriptionInfo) sessions = new ConcurrentHashMap<>();

		
// 		SessionSubscriptionInfo getSubscriptions(string sessionId) {
// 			return this.sessions.get(sessionId);
// 		}

// 		Collection!(SessionSubscriptionInfo) getAllSubscriptions() {
// 			return this.sessions.values();
// 		}

// 		SessionSubscriptionInfo addSubscription(string sessionId, string subscriptionId,
// 				string destination, Expression selectorExpression) {

// 			SessionSubscriptionInfo info = this.sessions.get(sessionId);
// 			if (info is null) {
// 				info = new SessionSubscriptionInfo(sessionId);
// 				SessionSubscriptionInfo value = this.sessions.putIfAbsent(sessionId, info);
// 				if (value !is null) {
// 					info = value;
// 				}
// 			}
// 			info.addSubscription(destination, subscriptionId, selectorExpression);
// 			return info;
// 		}

		
// 		SessionSubscriptionInfo removeSubscriptions(string sessionId) {
// 			return this.sessions.remove(sessionId);
// 		}

// 		override
// 		string toString() {
// 			return "registry[" ~ this.sessions.size() ~ " sessions]";
// 		}
// 	}


// 	/**
// 	 * Hold subscriptions for a session.
// 	 */
// 	private static class SessionSubscriptionInfo {

// 		private final string sessionId;

// 		// destination -> subscriptions
// 		private final Map!(string, Set!(Subscription)) destinationLookup = new ConcurrentHashMap<>(4);

// 		SessionSubscriptionInfo(string sessionId) {
// 			assert(sessionId, "'sessionId' must not be null");
// 			this.sessionId = sessionId;
// 		}

// 		string getSessionId() {
// 			return this.sessionId;
// 		}

// 		Set!(string) getDestinations() {
// 			return this.destinationLookup.keySet();
// 		}

// 		Set!(Subscription) getSubscriptions(string destination) {
// 			return this.destinationLookup.get(destination);
// 		}

		
// 		Subscription getSubscription(string subscriptionId) {
// 			for (Map.Entry<string, Set<DefaultSubscriptionRegistry.Subscription>> destinationEntry :
// 					this.destinationLookup.entrySet()) {
// 				for (Subscription sub : destinationEntry.getValue()) {
// 					if (sub.getId().equalsIgnoreCase(subscriptionId)) {
// 						return sub;
// 					}
// 				}
// 			}
// 			return null;
// 		}

// 		void addSubscription(string destination, string subscriptionId, Expression selectorExpression) {
// 			Set!(Subscription) subs = this.destinationLookup.get(destination);
// 			if (subs is null) {
// 				synchronized (this.destinationLookup) {
// 					subs = this.destinationLookup.get(destination);
// 					if (subs is null) {
// 						subs = new CopyOnWriteArraySet<>();
// 						this.destinationLookup.put(destination, subs);
// 					}
// 				}
// 			}
// 			subs.add(new Subscription(subscriptionId, selectorExpression));
// 		}

		
// 		string removeSubscription(string subscriptionId) {
// 			for (Map.Entry<string, Set<DefaultSubscriptionRegistry.Subscription>> destinationEntry :
// 					this.destinationLookup.entrySet()) {
// 				Set!(Subscription) subs = destinationEntry.getValue();
// 				if (subs !is null) {
// 					for (Subscription sub : subs) {
// 						if (sub.getId().equals(subscriptionId) && subs.remove(sub)) {
// 							synchronized (this.destinationLookup) {
// 								if (subs.isEmpty()) {
// 									this.destinationLookup.remove(destinationEntry.getKey());
// 								}
// 							}
// 							return destinationEntry.getKey();
// 						}
// 					}
// 				}
// 			}
// 			return null;
// 		}

// 		override
// 		string toString() {
// 			return "[sessionId=" ~ this.sessionId ~ ", subscriptions=" ~ this.destinationLookup ~ "]";
// 		}
// 	}


// 	private static final class Subscription {

// 		private final string id;

		
// 		private final Expression selectorExpression;

// 		Subscription(string id, Expression selector) {
// 			assert(id, "Subscription id must not be null");
// 			this.id = id;
// 			this.selectorExpression = selector;
// 		}

// 		string getId() {
// 			return this.id;
// 		}

		
// 		Expression getSelectorExpression() {
// 			return this.selectorExpression;
// 		}

// 		override
// 		bool opEquals(Object other) {
// 			return (this == other || (other instanceof Subscription && this.id.equals(((Subscription) other).id)));
// 		}

// 		override
// 		size_t toHash() @trusted nothrow {
// 			return this.id.toHash();
// 		}

// 		override
// 		string toString() {
// 			return "subscription(id=" ~ this.id ~ ")";
// 		}
// 	}


// 	private static class SimpMessageHeaderPropertyAccessor implements PropertyAccessor {

// 		override
// 		Class<?>[] getSpecificTargetClasses() {
// 			return new Class<?>[] {Message.class, MessageHeaders.class};
// 		}

// 		override
// 		 canRead(EvaluationContext context, Object target, string name) {
// 			return true;
// 		}

// 		override
// 		TypedValue read(EvaluationContext context, Object target, string name) {
// 			Object value;
// 			if (target instanceof Message) {
// 				value = name.equals("headers") ? ((Message) target).getHeaders() : null;
// 			}
// 			else if (target instanceof MessageHeaders) {
// 				MessageHeaders headers = (MessageHeaders) target;
// 				SimpMessageHeaderAccessor accessor =
// 						MessageHeaderAccessor.getAccessor(headers, SimpMessageHeaderAccessor.class);
// 				Assert.state(accessor !is null, "No SimpMessageHeaderAccessor");
// 				if ("destination".equalsIgnoreCase(name)) {
// 					value = accessor.getDestination();
// 				}
// 				else {
// 					value = accessor.getFirstNativeHeader(name);
// 					if (value is null) {
// 						value = headers.get(name);
// 					}
// 				}
// 			}
// 			else {
// 				// Should never happen...
// 				throw new IllegalStateException("Expected Message or MessageHeaders.");
// 			}
// 			return new TypedValue(value);
// 		}

// 		override
// 		 canWrite(EvaluationContext context, Object target, string name) {
// 			return false;
// 		}

// 		override
// 		void write(EvaluationContext context, Object target, string name, Object value) {
// 		}
// 	}

// }
