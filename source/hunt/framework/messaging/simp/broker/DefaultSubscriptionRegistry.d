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

import hunt.framework.messaging.simp.broker.AbstractSubscriptionRegistry;
import hunt.framework.messaging.simp.broker.SubscriptionRegistry;

import hunt.container;
import hunt.lang.exception;
import hunt.string.PathMatcher;

import std.array;
import std.conv;
import std.string;

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
class DefaultSubscriptionRegistry : AbstractSubscriptionRegistry {

	/** Default maximum number of entries for the destination cache: 1024. */
	enum int DEFAULT_CACHE_LIMIT = 1024;

	/** Static evaluation context to reuse. */
	// private __gshared EvaluationContext messageEvalContext;


	private PathMatcher pathMatcher;

	private int cacheLimit = DEFAULT_CACHE_LIMIT;
	
	private string selectorHeaderName = "selector";

	private bool selectorHeaderInUse = false;

	// private ExpressionParser expressionParser;

	private DestinationCache destinationCache;

	private SessionSubscriptionRegistry subscriptionRegistry;

    // shared static this() {
    //     messageEvalContext =
	// 		SimpleEvaluationContext.forPropertyAccessors(new SimpMessageHeaderPropertyAccessor()).build();
    // }

    this() {
        pathMatcher = new AntPathMatcher();
        // expressionParser = new SpelExpressionParser();
        destinationCache = new DestinationCache();
        subscriptionRegistry = new SessionSubscriptionRegistry();
    }


	/**
	 * Specify the {@link PathMatcher} to use.
	 */
	void setPathMatcher(PathMatcher pathMatcher) {
		this.pathMatcher = pathMatcher;
	}

	/**
	 * Return the configured {@link PathMatcher}.
	 */
	PathMatcher getPathMatcher() {
		return this.pathMatcher;
	}

	/**
	 * Specify the maximum number of entries for the resolved destination cache.
	 * Default is 1024.
	 */
	void setCacheLimit(int cacheLimit) {
		this.cacheLimit = cacheLimit;
	}

	/**
	 * Return the maximum number of entries for the resolved destination cache.
	 */
	int getCacheLimit() {
		return this.cacheLimit;
	}

	/**
	 * Configure the name of a header that a subscription message can have for
	 * the purpose of filtering messages matched to the subscription. The header
	 * value is expected to be a Spring EL  expression to be applied to
	 * the headers of messages matched to the subscription.
	 * <p>For example:
	 * <pre>
	 * headers.foo == 'bar'
	 * </pre>
	 * <p>By default this is set to "selector". You can set it to a different
	 * name, or to {@code null} to turn off support for a selector header.
	 * @param selectorHeaderName the name to use for a selector header
	 * @since 4.2
	 */
	void setSelectorHeaderName(string selectorHeaderName) {
		this.selectorHeaderName = selectorHeaderName;
	}

	/**
	 * Return the name for the selector header name.
	 * @since 4.2
	 */
	
	string getSelectorHeaderName() {
		return this.selectorHeaderName;
	}


	override
	protected void addSubscriptionInternal(
			string sessionId, string subsId, string destination, MessageBase message) {

		// Expression expression = getSelectorExpression(message.getHeaders());
		// this.subscriptionRegistry.addSubscription(sessionId, subsId, destination, expression);
        this.subscriptionRegistry.addSubscription(sessionId, subsId, destination);
		this.destinationCache.updateAfterNewSubscription(destination, sessionId, subsId);
	}

	
	// private Expression getSelectorExpression(MessageHeaders headers) {
	// 	Expression expression = null;
	// 	if (getSelectorHeaderName() !is null) {
	// 		string selector = SimpMessageHeaderAccessor.getFirstNativeHeader(getSelectorHeaderName(), headers);
	// 		if (selector !is null) {
	// 			try {
	// 				expression = this.expressionParser.parseExpression(selector);
	// 				this.selectorHeaderInUse = true;
	// 				version(HUNT_DEBUG) {
	// 					trace("Subscription selector: [" ~ selector ~ "]");
	// 				}
	// 			}
	// 			catch (Throwable ex) {
	// 				version(HUNT_DEBUG) {
	// 					trace("Failed to parse selector: " ~ selector, ex);
	// 				}
	// 			}
	// 		}
	// 	}
	// 	return expression;
	// }

	override
	protected void removeSubscriptionInternal(string sessionId, string subsId, MessageBase message) {
		SessionSubscriptionInfo info = this.subscriptionRegistry.getSubscriptions(sessionId);
		if (info !is null) {
			string destination = info.removeSubscription(subsId);
			if (destination !is null) {
				this.destinationCache.updateAfterRemovedSubscription(sessionId, subsId);
			}
		}
	}

	// override
	void unregisterAllSubscriptions(string sessionId) {
		SessionSubscriptionInfo info = this.subscriptionRegistry.removeSubscriptions(sessionId);
		if (info !is null) {
			this.destinationCache.updateAfterRemovedSession(info);
		}
	}

	override
	protected MultiValueMap!(string, string) findSubscriptionsInternal(string destination, MessageBase message) {
		MultiValueMap!(string, string) result = this.destinationCache.getSubscriptions(destination, message);
		return filterSubscriptions(result, message);
	}

	private MultiValueMap!(string, string) filterSubscriptions(
			MultiValueMap!(string, string) allMatches, MessageBase message) {

		if (!this.selectorHeaderInUse) {
			return allMatches;
		}
		MultiValueMap!(string, string) result = new LinkedMultiValueMap!(string, string)(allMatches.size());
        implementationMissing(false);
		// allMatches.forEach((sessionId, subIds) -> {
		// 	for (string subId : subIds) {
		// 		SessionSubscriptionInfo info = this.subscriptionRegistry.getSubscriptions(sessionId);
		// 		if (info is null) {
		// 			continue;
		// 		}
		// 		Subscription sub = info.getSubscription(subId);
		// 		if (sub is null) {
		// 			continue;
		// 		}
		// 		Expression expression = sub.getSelectorExpression();
		// 		if (expression is null) {
		// 			result.add(sessionId, subId);
		// 			continue;
		// 		}
		// 		try {
		// 			if (Boolean.TRUE.equals(expression.getValue(messageEvalContext, message, Boolean.class))) {
		// 				result.add(sessionId, subId);
		// 			}
		// 		}
		// 		catch (SpelEvaluationException ex) {
		// 			version(HUNT_DEBUG) {
		// 				trace("Failed to evaluate selector: " ~ ex.getMessage());
		// 			}
		// 		}
		// 		catch (Throwable ex) {
		// 			trace("Failed to evaluate selector", ex);
		// 		}
		// 	}
		// });
		return result;
	}

	override
	string toString() {
		return "DefaultSubscriptionRegistry[" ~ this.destinationCache.toString() ~ 
			", " ~ this.subscriptionRegistry.toString() ~ "]";
	}


	/**
	 * A cache for destinations previously resolved via
	 * {@link DefaultSubscriptionRegistry#findSubscriptionsInternal(string, Message)}.
	 */
	private class DestinationCache {

		/** Map from destination to {@code <sessionId, subscriptionId>} for fast look-ups. */
		private Map!(string, LinkedMultiValueMap!(string, string)) accessCache;

		/** Map from destination to {@code <sessionId, subscriptionId>} with locking. */
		
		private Map!(string, LinkedMultiValueMap!(string, string)) updateCache;


        this() {
            accessCache = new HashMap!(string, LinkedMultiValueMap!(string, string))(DEFAULT_CACHE_LIMIT);

            updateCache =
				new class LinkedHashMap!(string, LinkedMultiValueMap!(string, string)) {
					this() {
						super(DEFAULT_CACHE_LIMIT, 0.75f, true);
					}

					override
					protected bool removeEldestEntry(MapEntry!(string, LinkedMultiValueMap!(string, string)) eldest) {
						if (size() > getCacheLimit()) {
							accessCache.remove(eldest.getKey());
							return true;
						}
						else {
							return false;
						}
					}
				};            
        }


		LinkedMultiValueMap!(string, string) getSubscriptions(string destination, MessageBase message) {
			LinkedMultiValueMap!(string, string) result = this.accessCache.get(destination);
			if (result is null) {
				synchronized (this.updateCache) {
					result = new LinkedMultiValueMap!(string, string)();
					foreach (SessionSubscriptionInfo info ; subscriptionRegistry.getAllSubscriptions()) {
						foreach (string destinationPattern ; info.getDestinations()) {
							if (getPathMatcher().match(destinationPattern, destination)) {
								foreach (Subscription sub ; info.getSubscriptions(destinationPattern)) {
									result.add(info.sessionId, sub.getId());
								}
							}
						}
					}
					if (!result.isEmpty()) {
						this.updateCache.put(destination, result.deepCopy());
						this.accessCache.put(destination, result);
					}
				}
			}
			return result;
		}

		void updateAfterNewSubscription(string destination, string sessionId, string subsId) {
			synchronized (this.updateCache) {
				foreach(string cachedDestination, 
					LinkedMultiValueMap!(string, string) subscriptions; this.updateCache) {
					if (getPathMatcher().match(destination, cachedDestination)) {
						// Subscription id's may also be populated via getSubscriptions()
						List!(string) subsForSession = subscriptions.get(sessionId);
						if (subsForSession is null || !subsForSession.contains(subsId)) {
							subscriptions.add(sessionId, subsId);
							this.accessCache.put(cachedDestination, subscriptions.deepCopy());
						}
					}
				}
			}
		}

		void updateAfterRemovedSubscription(string sessionId, string subsId) {
			synchronized (this.updateCache) {
				Set!(string) destinationsToRemove = new HashSet!(string)();

				foreach(string destination, 
					LinkedMultiValueMap!(string, string) sessionMap; this.updateCache) {
					List!(string) subscriptions = sessionMap.get(sessionId);
					if (subscriptions !is null) {
						subscriptions.remove(subsId);
						if (subscriptions.isEmpty()) {
							sessionMap.remove(sessionId);
						}
						if (sessionMap.isEmpty()) {
							destinationsToRemove.add(destination);
						}
						else {
							this.accessCache.put(destination, sessionMap.deepCopy());
						}
					}
				}

				foreach (string destination ; destinationsToRemove) {
					this.updateCache.remove(destination);
					this.accessCache.remove(destination);
				}
			}
		}

		void updateAfterRemovedSession(SessionSubscriptionInfo info) {
			synchronized (this.updateCache) {
				Set!(string) destinationsToRemove = new HashSet!(string)();

				foreach(string destination, 
					LinkedMultiValueMap!(string, string) sessionMap; this.updateCache) {
					if (sessionMap.remove(info.getSessionId()) !is null) {
						if (sessionMap.isEmpty()) {
							destinationsToRemove.add(destination);
						}
						else {
							this.accessCache.put(destination, sessionMap.deepCopy());
						}
					}
				}

				foreach (string destination ; destinationsToRemove) {
					this.updateCache.remove(destination);
					this.accessCache.remove(destination);
				}
			}
		}

		override
		string toString() {
			return "cache[" ~ this.accessCache.size().to!string() ~ " destination(s)]";
		}
	}


}


/**
 * Provide access to session subscriptions by sessionId.
 */
private static class SessionSubscriptionRegistry {

    // sessionId -> SessionSubscriptionInfo
    // private ConcurrentMap!(string, SessionSubscriptionInfo) sessions = new ConcurrentHashMap<>();
    private Map!(string, SessionSubscriptionInfo) sessions;

    this() {
        sessions = new HashMap!(string, SessionSubscriptionInfo)();
    }

    
    SessionSubscriptionInfo getSubscriptions(string sessionId) {
        return this.sessions.get(sessionId);
    }

    SessionSubscriptionInfo[] getAllSubscriptions() {
        return this.sessions.values();
    }

    SessionSubscriptionInfo addSubscription(string sessionId, string subscriptionId,
        string destination) {
            // string destination, Expression selectorExpression) {

        SessionSubscriptionInfo info = this.sessions.get(sessionId);
        if (info is null) {
            info = new SessionSubscriptionInfo(sessionId);
            SessionSubscriptionInfo value = this.sessions.putIfAbsent(sessionId, info);
            if (value !is null) {
                info = value;
            }
        }
        // info.addSubscription(destination, subscriptionId, selectorExpression);
        info.addSubscription(destination, subscriptionId);
        return info;
    }

    
    SessionSubscriptionInfo removeSubscriptions(string sessionId) {
        return this.sessions.remove(sessionId);
    }

    override
    string toString() {
        return "registry[" ~ this.sessions.size().to!string() ~ " sessions]";
    }
}


/**
 * Hold subscriptions for a session.
 */
private class SessionSubscriptionInfo {

    private string sessionId;

    // destination -> subscriptions
    private Map!(string, Set!(Subscription)) destinationLookup;

    this(string sessionId) {
        assert(sessionId, "'sessionId' must not be null");
        this.sessionId = sessionId;
        destinationLookup = new HashMap!(string, Set!(Subscription))(4); // new ConcurrentHashMap<>(4);
    }

    string getSessionId() {
        return this.sessionId;
    }

    string[] getDestinations() {
        return this.destinationLookup.byKey.array; // .keySet();
    }

    Set!(Subscription) getSubscriptions(string destination) {
        return this.destinationLookup.get(destination);
    }

    
    Subscription getSubscription(string subscriptionId) {
        // for (Map.Entry<string, Set<Subscription>> destinationEntry :
        //         this.destinationLookup.entrySet()) {
        foreach(Set!(Subscription) value; this.destinationLookup.byValue())  {            
            foreach (Subscription sub ; value) {
                if (icmp(sub.getId(), subscriptionId)) {
                    return sub;
                }
            }
        }
        return null;
    }

    // void addSubscription(string destination, string subscriptionId, Expression selectorExpression) {
    void addSubscription(string destination, string subscriptionId) {
        Set!(Subscription) subs = this.destinationLookup.get(destination);
        if (subs is null) {
            synchronized (this.destinationLookup) {
                subs = this.destinationLookup.get(destination);
                if (subs is null) {
                    // TODO: Tasks pending completion -@zxp at 10/31/2018, 1:41:41 PM
                    // 
                    // subs = new CopyOnWriteArraySet<>();
                    subs = new HashSet!(Subscription)();
                    this.destinationLookup.put(destination, subs);
                }
            }
        }
        // subs.add(new Subscription(subscriptionId, selectorExpression));
        subs.add(new Subscription(subscriptionId));
    }

    
    string removeSubscription(string subscriptionId) {
        // for (Map.Entry<string, Set<DefaultSubscriptionRegistry.Subscription>> destinationEntry :
        //         this.destinationLookup.entrySet()) {
        foreach(string key, Set!(Subscription) subs; this.destinationLookup)  {
            if (subs !is null) {
                foreach (Subscription sub ; subs) {
                    if (sub.getId() == subscriptionId && subs.remove(sub)) {
                        synchronized (this.destinationLookup) {
                            if (subs.isEmpty()) {
                                this.destinationLookup.remove(key);
                            }
                        }
                        return key;
                    }
                }
            }
        }
        return null;
    }

    override
    string toString() {
        return "[sessionId=" ~ this.sessionId ~ ", subscriptions=" ~ this.destinationLookup.toString() ~ "]";
    }
}


private final class Subscription {

    private string id;
    
    // private Expression selectorExpression;

    // this(string id, Expression selector) {
    this(string id) {        
        assert(id, "Subscription id must not be null");
        this.id = id;
        // this.selectorExpression = selector;
    }

    string getId() {
        return this.id;
    }

    
    // Expression getSelectorExpression() {
    //     return this.selectorExpression;
    // }

    override
    bool opEquals(Object other) {
        if(this is other)
            return true;
        Subscription ot = cast(Subscription) other;
        if(ot is null)
            return false;
        return this.id == ot.id;
    }

    override
    size_t toHash() @trusted nothrow {
        return hashOf(this.id);
    }

    override
    string toString() {
        return "subscription(id=" ~ this.id ~ ")";
    }
}


// private class SimpMessageHeaderPropertyAccessor : PropertyAccessor {

//     override
//     Class<?>[] getSpecificTargetClasses() {
//         return new Class<?>[] {Message.class, MessageHeaders.class};
//     }

//     override
//         canRead(EvaluationContext context, Object target, string name) {
//         return true;
//     }

//     override
//     TypedValue read(EvaluationContext context, Object target, string name) {
//         Object value;
//         if (target instanceof Message) {
//             value = name.equals("headers") ? ((Message) target).getHeaders() : null;
//         }
//         else if (target instanceof MessageHeaders) {
//             MessageHeaders headers = (MessageHeaders) target;
//             SimpMessageHeaderAccessor accessor =
//                     MessageHeaderAccessor.getAccessor(headers, SimpMessageHeaderAccessor.class);
//             assert(accessor !is null, "No SimpMessageHeaderAccessor");
//             if ("destination".equalsIgnoreCase(name)) {
//                 value = accessor.getDestination();
//             }
//             else {
//                 value = accessor.getFirstNativeHeader(name);
//                 if (value is null) {
//                     value = headers.get(name);
//                 }
//             }
//         }
//         else {
//             // Should never happen...
//             throw new IllegalStateException("Expected Message or MessageHeaders.");
//         }
//         return new TypedValue(value);
//     }

//     override
//         canWrite(EvaluationContext context, Object target, string name) {
//         return false;
//     }

//     override
//     void write(EvaluationContext context, Object target, string name, Object value) {
//     }
// }
