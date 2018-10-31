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

module hunt.framework.messaging.simp.annotation.AbstractMethodMessageHandler;

import hunt.container;
import hunt.lang.exception;
import hunt.logging;
import hunt.util.TypeUtils;

import std.array;
import std.conv;
import std.string;

// import hunt.framework.beans.factory.InitializingBean;
import hunt.framework.context.ApplicationContext;
// import hunt.framework.context.ApplicationContextAware;
// import hunt.framework.core.MethodIntrospector;
// import hunt.framework.core.MethodParameter;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.handler.DestinationPatternsMessageCondition;
// import hunt.framework.messaging.handler.HandlerMethod;
// import hunt.framework.messaging.handler.MessagingAdviceBean;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

// import hunt.framework.util.ClassUtils;
// import hunt.framework.util.CollectionUtils;
// import hunt.framework.util.LinkedMultiValueMap;
// import hunt.framework.util.MultiValueMap;
// import hunt.framework.util.concurrent.ListenableFuture;
// import hunt.framework.util.concurrent.ListenableFutureCallback;

/**
 * Abstract base class for HandlerMethod-based message handling. Provides most of
 * the logic required to discover handler methods at startup, find a matching handler
 * method at runtime for a given message and invoke it.
 *
 * <p>Also supports discovering and invoking exception handling methods to process
 * exceptions raised during message handling.
 *
 * @author Rossen Stoyanchev
 * @author Juergen Hoeller
 * @since 4.0
 * @param (T) the type of the Object that contains information mapping a
 * {@link hunt.framework.messaging.handler.HandlerMethod} to incoming messages
 */
abstract class AbstractMethodMessageHandler(T)
		: MessageHandler { // , ApplicationContextAware, InitializingBean 

	/**
	 * Bean name prefix for target beans behind scoped proxies. Used to exclude those
	 * targets from handler method detection, in favor of the corresponding proxies.
	 * <p>We're not checking the autowire-candidate status here, which is how the
	 * proxy target filtering problem is being handled at the autowiring level,
	 * since autowire-candidate may have been turned to {@code false} for other
	 * reasons, while still expecting the bean to be eligible for handler methods.
	 * <p>Originally defined in {@link hunt.framework.aop.scope.ScopedProxyUtils}
	 * but duplicated here to avoid a hard dependency on the spring-aop module.
	 */
	private enum string SCOPED_TARGET_NAME_PREFIX = "scopedTarget.";

	private string[] destinationPrefixes;

	// private List!(HandlerMethodArgumentResolver) customArgumentResolvers = new ArrayList<>(4);

	// private List!(HandlerMethodReturnValueHandler) customReturnValueHandlers = new ArrayList<>(4);

	// private HandlerMethodArgumentResolverComposite argumentResolvers =
	// 		new HandlerMethodArgumentResolverComposite();

	// private HandlerMethodReturnValueHandlerComposite returnValueHandlers =
	// 		new HandlerMethodReturnValueHandlerComposite();

	
	private ApplicationContext applicationContext;

	// private Map!(T, HandlerMethod) handlerMethods = new LinkedHashMap<>(64);

	// private MultiValueMap!(string, T) destinationLookup = new LinkedMultiValueMap<>(64);

	// private Map<Class<?>, AbstractExceptionHandlerMethodResolver> exceptionHandlerCache =
	// 		new ConcurrentHashMap<>(64);

	// private Map!(MessagingAdviceBean, AbstractExceptionHandlerMethodResolver) exceptionHandlerAdviceCache =
	// 		new LinkedHashMap<>(64);

	this() {

	}

	/**
	 * When this property is configured only messages to destinations matching
	 * one of the configured prefixes are eligible for handling. When there is a
	 * match the prefix is removed and only the remaining part of the destination
	 * is used for method-mapping purposes.
	 * <p>By default, no prefixes are configured in which case all messages are
	 * eligible for handling.
	 */
	void setDestinationPrefixes(string[] prefixes) {
		this.destinationPrefixes = [];
		if (prefixes.length > 0) {
			foreach (string prefix ; prefixes) {
				prefix = prefix.strip();
				this.destinationPrefixes ~= prefix;
			}
		}
	}

	/**
	 * Return the configured destination prefixes, if any.
	 */
	string[] getDestinationPrefixes() {
		return this.destinationPrefixes;
	}

	/**
	 * Sets the list of custom {@code HandlerMethodArgumentResolver}s that will be used
	 * after resolvers for supported argument type.
	 */
	// void setCustomArgumentResolvers(List!(HandlerMethodArgumentResolver) customArgumentResolvers) {
	// 	this.customArgumentResolvers.clear();
	// 	if (customArgumentResolvers !is null) {
	// 		this.customArgumentResolvers.addAll(customArgumentResolvers);
	// 	}
	// }

	/**
	 * Return the configured custom argument resolvers, if any.
	 */
	// List!(HandlerMethodArgumentResolver) getCustomArgumentResolvers() {
	// 	return this.customArgumentResolvers;
	// }

	/**
	 * Set the list of custom {@code HandlerMethodReturnValueHandler}s that will be used
	 * after return value handlers for known types.
	 */
	// void setCustomReturnValueHandlers(List!(HandlerMethodReturnValueHandler) customReturnValueHandlers) {
	// 	this.customReturnValueHandlers.clear();
	// 	if (customReturnValueHandlers !is null) {
	// 		this.customReturnValueHandlers.addAll(customReturnValueHandlers);
	// 	}
	// }

	/**
	 * Return the configured custom return value handlers, if any.
	 */
	// List!(HandlerMethodReturnValueHandler) getCustomReturnValueHandlers() {
	// 	return this.customReturnValueHandlers;
	// }

	/**
	 * Configure the complete list of supported argument types, effectively overriding
	 * the ones configured by default. This is an advanced option; for most use cases
	 * it should be sufficient to use {@link #setCustomArgumentResolvers}.
	 */
	// void setArgumentResolvers(List!(HandlerMethodArgumentResolver) argumentResolvers) {
	// 	if (argumentResolvers is null) {
	// 		this.argumentResolvers.clear();
	// 		return;
	// 	}
	// 	this.argumentResolvers.addResolvers(argumentResolvers);
	// }

	/**
	 * Return the complete list of argument resolvers.
	 */
	// List!(HandlerMethodArgumentResolver) getArgumentResolvers() {
	// 	return this.argumentResolvers.getResolvers();
	// }

	/**
	 * Configure the complete list of supported return value types, effectively overriding
	 * the ones configured by default. This is an advanced option; for most use cases
	 * it should be sufficient to use {@link #setCustomReturnValueHandlers}.
	 */
	// void setReturnValueHandlers(List!(HandlerMethodReturnValueHandler) returnValueHandlers) {
	// 	if (returnValueHandlers is null) {
	// 		this.returnValueHandlers.clear();
	// 		return;
	// 	}
	// 	this.returnValueHandlers.addHandlers(returnValueHandlers);
	// }

	/**
	 * Return the complete list of return value handlers.
	 */
	// List!(HandlerMethodReturnValueHandler) getReturnValueHandlers() {
	// 	return this.returnValueHandlers.getReturnValueHandlers();
	// }

	// override
	void setApplicationContext(ApplicationContext applicationContext) {
		this.applicationContext = applicationContext;
	}

	
	ApplicationContext getApplicationContext() {
		return this.applicationContext;
	}


	// override
	void afterPropertiesSet() {
		implementationMissing(false);
		// if (this.argumentResolvers.getResolvers().isEmpty()) {
		// 	this.argumentResolvers.addResolvers(initArgumentResolvers());
		// }

		// if (this.returnValueHandlers.getReturnValueHandlers().isEmpty()) {
		// 	this.returnValueHandlers.addHandlers(initReturnValueHandlers());
		// }
		// Log returnValueLogger = getReturnValueHandlerLogger();
		// if (returnValueLogger !is null) {
		// 	this.returnValueHandlers.setLogger(returnValueLogger);
		// }

		// this.handlerMethodLogger = getHandlerMethodLogger();

		// ApplicationContext context = getApplicationContext();
		// if (context is null) {
		// 	return;
		// }
		// for (string beanName : context.getBeanNamesForType(Object.class)) {
		// 	if (!beanName.startsWith(SCOPED_TARGET_NAME_PREFIX)) {
		// 		Class<?> beanType = null;
		// 		try {
		// 			beanType = context.getType(beanName);
		// 		}
		// 		catch (Throwable ex) {
		// 			// An unresolvable bean type, probably from a lazy bean - let's ignore it.
		// 			version(HUNT_DEBUG) {
		// 				trace("Could not resolve target class for bean with name '" ~ beanName ~ "'", ex);
		// 			}
		// 		}
		// 		if (beanType !is null && isHandler(beanType)) {
		// 			detectHandlerMethods(beanName);
		// 		}
		// 	}
		// }
	}

	/**
	 * Return the list of argument resolvers to use. Invoked only if the resolvers
	 * have not already been set via {@link #setArgumentResolvers}.
	 * <p>Subclasses should also take into account custom argument types configured via
	 * {@link #setCustomArgumentResolvers}.
	 */
	// protected abstract List!(HandlerMethodArgumentResolver) initArgumentResolvers();

	/**
	 * Return the list of return value handlers to use. Invoked only if the return
	 * value handlers have not already been set via {@link #setReturnValueHandlers}.
	 * <p>Subclasses should also take into account custom return value types configured
	 * via {@link #setCustomReturnValueHandlers}.
	 */
	// protected abstract List!(HandlerMethodReturnValueHandler) initReturnValueHandlers();


	/**
	 * Whether the given bean type should be introspected for messaging handling methods.
	 */
	// protected abstract  isHandler(Class<?> beanType);

	/**
	 * Detect if the given handler has any methods that can handle messages and if
	 * so register it with the extracted mapping information.
	 * @param handler the handler to check, either an instance of a Spring bean name
	 */
	// protected final void detectHandlerMethods(Object handler) {
	// 	Class<?> handlerType;
	// 	if (handler instanceof string) {
	// 		ApplicationContext context = getApplicationContext();
	// 		assert(context !is null, "ApplicationContext is required for resolving handler bean names");
	// 		handlerType = context.getType((string) handler);
	// 	}
	// 	else {
	// 		handlerType = handler.getClass();
	// 	}

	// 	if (handlerType !is null) {
	// 		Class<?> userType = ClassUtils.getUserClass(handlerType);
	// 		Map!(Method, T) methods = MethodIntrospector.selectMethods(userType,
	// 				(MethodIntrospector.MetadataLookup!(T)) method -> getMappingForMethod(method, userType));
	// 		version(HUNT_DEBUG) {
	// 			trace(methods.size() ~ " message handler methods found on " ~ userType ~ ": " ~ methods);
	// 		}
	// 		methods.forEach((key, value) -> registerHandlerMethod(handler, key, value));
	// 	}
	// }

	/**
	 * Provide the mapping for a handler method.
	 * @param method the method to provide a mapping for
	 * @param handlerType the handler type, possibly a sub-type of the method's declaring class
	 * @return the mapping, or {@code null} if the method is not mapped
	 */
	
	// protected abstract T getMappingForMethod(Method method, Class<?> handlerType);

	/**
	 * Register a handler method and its unique mapping.
	 * @param handler the bean name of the handler or the handler instance
	 * @param method the method to register
	 * @param mapping the mapping conditions associated with the handler method
	 * @throws IllegalStateException if another method was already registered
	 * under the same mapping
	 */
	// protected void registerHandlerMethod(Object handler, Method method, T mapping) {
	// 	assert(mapping, "Mapping must not be null");
	// 	HandlerMethod newHandlerMethod = createHandlerMethod(handler, method);
	// 	HandlerMethod oldHandlerMethod = this.handlerMethods.get(mapping);

	// 	if (oldHandlerMethod !is null && !oldHandlerMethod.equals(newHandlerMethod)) {
	// 		throw new IllegalStateException("Ambiguous mapping found. Cannot map '" ~ newHandlerMethod.getBean() +
	// 				"' bean method \n" ~ newHandlerMethod ~ "\nto " ~ mapping ~ ": There is already '" ~
	// 				oldHandlerMethod.getBean() ~ "' bean method\n" ~ oldHandlerMethod ~ " mapped.");
	// 	}

	// 	this.handlerMethods.put(mapping, newHandlerMethod);
	// 	version(HUNT_DEBUG) {
	// 		trace("Mapped \"" ~ mapping ~ "\" onto " ~ newHandlerMethod);
	// 	}

	// 	for (string pattern : getDirectLookupDestinations(mapping)) {
	// 		this.destinationLookup.add(pattern, mapping);
	// 	}
	// }

	/**
	 * Create a HandlerMethod instance from an Object handler that is either a handler
	 * instance or a string-based bean name.
	 */
	// protected HandlerMethod createHandlerMethod(Object handler, Method method) {
	// 	HandlerMethod handlerMethod;
	// 	if (handler instanceof string) {
	// 		ApplicationContext context = getApplicationContext();
	// 		assert(context !is null, "ApplicationContext is required for resolving handler bean names");
	// 		string beanName = (string) handler;
	// 		handlerMethod = new HandlerMethod(beanName, context.getAutowireCapableBeanFactory(), method);
	// 	}
	// 	else {
	// 		handlerMethod = new HandlerMethod(handler, method);
	// 	}
	// 	return handlerMethod;
	// }

	/**
	 * Return destinations contained in the mapping that are not patterns and are
	 * therefore suitable for direct lookups.
	 */
	// protected abstract Set!(string) getDirectLookupDestinations(T mapping);

	/**
	 * Return a logger to set on {@link HandlerMethodReturnValueHandlerComposite}.
	 * @since 5.1
	 */
	
	// protected Log getReturnValueHandlerLogger() {
	// 	return null;
	// }

	/**
	 * Return a logger to set on {@link InvocableHandlerMethod}.
	 * @since 5.1
	 */
	
	// protected Log getHandlerMethodLogger() {
	// 	return null;
	// }

	/**
	 * Subclasses can invoke this method to populate the MessagingAdviceBean cache
	 * (e.g. to support "global" {@code @MessageExceptionHandler}).
	 * @since 4.2
	 */
	// protected void registerExceptionHandlerAdvice(
	// 		MessagingAdviceBean bean, AbstractExceptionHandlerMethodResolver resolver) {

	// 	this.exceptionHandlerAdviceCache.put(bean, resolver);
	// }

	/**
	 * Return a map with all handler methods and their mappings.
	 */
	// Map!(T, HandlerMethod) getHandlerMethods() {
	// 	return Collections.unmodifiableMap(this.handlerMethods);
	// }


	override
	void handleMessage(MessageBase message) {
		string destination = getDestination(message);
		if (destination is null) {
			return;
		}
		string lookupDestination = getLookupDestination(destination);
		if (lookupDestination is null) {
			return;
		}

		MessageHeaderAccessor headerAccessor = MessageHeaderAccessor.getMutableAccessor(message);
		headerAccessor.setHeader(DestinationPatternsMessageCondition.LOOKUP_DESTINATION_HEADER, lookupDestination);
		headerAccessor.setLeaveMutable(true);
		implementationMissing(false);
		warning(message.payloadType);
		// message = MessageHelper.createMessage(message.getPayload(), headerAccessor.getMessageHeaders());

		// version(HUNT_DEBUG) {
		// 	trace("Searching methods to handle " ~
		// 			headerAccessor.getShortLogMessage(message.getPayload()) ~
		// 			", lookupDestination='" ~ lookupDestination ~ "'");
		// }

		handleMessageInternal(message, lookupDestination);
		headerAccessor.setImmutable();
	}

	
	protected abstract string getDestination(MessageBase message);

	/**
	 * Check whether the given destination (of an incoming message) matches to
	 * one of the configured destination prefixes and if so return the remaining
	 * portion of the destination after the matched prefix.
	 * <p>If there are no matching prefixes, return {@code null}.
	 * <p>If there are no destination prefixes, return the destination as is.
	 */
	
	
	protected string getLookupDestination(string destination) {
		if (destination.empty()) {
			return null;
		}
		if (this.destinationPrefixes.length >0) {
			return destination;
		}
		for (size_t i = 0; i < this.destinationPrefixes.length; i++) {
			string prefix = this.destinationPrefixes[i];
			if (destination.startsWith(prefix)) {
				return destination[prefix.length .. $];
			}
		}
		return null;
	}

	protected void handleMessageInternal(MessageBase message, string lookupDestination) {
		implementationMissing(false);
		// List!(Match) matches = new ArrayList<>();

		// List!(T) mappingsByUrl = this.destinationLookup.get(lookupDestination);
		// if (mappingsByUrl !is null) {
		// 	addMatchesToCollection(mappingsByUrl, message, matches);
		// }
		// if (matches.isEmpty()) {
		// 	// No direct hits, go through all mappings
		// 	Set!(T) allMappings = this.handlerMethods.keySet();
		// 	addMatchesToCollection(allMappings, message, matches);
		// }
		// if (matches.isEmpty()) {
		// 	handleNoMatch(this.handlerMethods.keySet(), lookupDestination, message);
		// 	return;
		// }

		// Comparator!(Match) comparator = new MatchComparator(getMappingComparator(message));
		// matches.sort(comparator);
		// version(HUNT_DEBUG) {
		// 	trace("Found " ~ matches.size() ~ " handler methods: " ~ matches);
		// }

		// Match bestMatch = matches.get(0);
		// if (matches.size() > 1) {
		// 	Match secondBestMatch = matches.get(1);
		// 	if (comparator.compare(bestMatch, secondBestMatch) == 0) {
		// 		Method m1 = bestMatch.handlerMethod.getMethod();
		// 		Method m2 = secondBestMatch.handlerMethod.getMethod();
		// 		throw new IllegalStateException("Ambiguous handler methods mapped for destination '" ~
		// 				lookupDestination ~ "': {" ~ m1 ~ ", " ~ m2 ~ "}");
		// 	}
		// }

		// handleMatch(bestMatch.mapping, bestMatch.handlerMethod, lookupDestination, message);
	}

	// private void addMatchesToCollection(Collection!(T) mappingsToCheck, MessageBase message, List!(Match) matches) {
	// 	foreach (T mapping ; mappingsToCheck) {
	// 		T match = getMatchingMapping(mapping, message);
	// 		if (match !is null) {
	// 			matches.add(new Match(match, this.handlerMethods.get(mapping)));
	// 		}
	// 	}
	// }

	/**
	 * Check if a mapping matches the current message and return a possibly
	 * new mapping with conditions relevant to the current request.
	 * @param mapping the mapping to get a match for
	 * @param message the message being handled
	 * @return the match or {@code null} if there is no match
	 */
	
	// protected abstract T getMatchingMapping(T mapping, MessageBase message);

	protected void handleNoMatch(Set!(T) ts, string lookupDestination, MessageBase message) {
		trace("No matching message handler methods.");
	}

	/**
	 * Return a comparator for sorting matching mappings.
	 * The returned comparator should sort 'better' matches higher.
	 * @param message the current Message
	 * @return the comparator, never {@code null}
	 */
	// protected abstract Comparator!(T) getMappingComparator(MessageBase message);

	// protected void handleMatch(T mapping, HandlerMethod handlerMethod, string lookupDestination, MessageBase message) {
	// 	version(HUNT_DEBUG) {
	// 		trace("Invoking " ~ handlerMethod.getShortLogMessage());
	// 	}
	// 	handlerMethod = handlerMethod.createWithResolvedBean();
	// 	InvocableHandlerMethod invocable = new InvocableHandlerMethod(handlerMethod);
	// 	if (this.handlerMethodLogger !is null) {
	// 		invocable.setLogger(this.handlerMethodLogger);
	// 	}
	// 	invocable.setMessageMethodArgumentResolvers(this.argumentResolvers);
	// 	try {
	// 		Object returnValue = invocable.invoke(message);
	// 		MethodParameter returnType = handlerMethod.getReturnType();
	// 		if (void.class == returnType.getParameterType()) {
	// 			return;
	// 		}
	// 		if (returnValue !is null && this.returnValueHandlers.isAsyncReturnValue(returnValue, returnType)) {
	// 			ListenableFuture<?> future = this.returnValueHandlers.toListenableFuture(returnValue, returnType);
	// 			if (future !is null) {
	// 				future.addCallback(new ReturnValueListenableFutureCallback(invocable, message));
	// 			}
	// 		}
	// 		else {
	// 			this.returnValueHandlers.handleReturnValue(returnValue, returnType, message);
	// 		}
	// 	}
	// 	catch (Exception ex) {
	// 		processHandlerMethodException(handlerMethod, ex, message);
	// 	}
	// 	catch (Throwable ex) {
	// 		Exception handlingException =
	// 				new MessageHandlingException(message, "Unexpected handler method invocation error", ex);
	// 		processHandlerMethodException(handlerMethod, handlingException, message);
	// 	}
	// }

	// protected void processHandlerMethodException(HandlerMethod handlerMethod, Exception exception, MessageBase message) {
	// 	InvocableHandlerMethod invocable = getExceptionHandlerMethod(handlerMethod, exception);
	// 	if (invocable is null) {
	// 		error("Unhandled exception from message handler method", exception);
	// 		return;
	// 	}
	// 	invocable.setMessageMethodArgumentResolvers(this.argumentResolvers);
	// 	version(HUNT_DEBUG) {
	// 		trace("Invoking " ~ invocable.getShortLogMessage());
	// 	}
	// 	try {
	// 		Throwable cause = exception.getCause();
	// 		Object returnValue = (cause !is null ?
	// 				invocable.invoke(message, exception, cause, handlerMethod) :
	// 				invocable.invoke(message, exception, handlerMethod));
	// 		MethodParameter returnType = invocable.getReturnType();
	// 		if (void.class == returnType.getParameterType()) {
	// 			return;
	// 		}
	// 		this.returnValueHandlers.handleReturnValue(returnValue, returnType, message);
	// 	}
	// 	catch (Throwable ex2) {
	// 		error("Error while processing handler method exception", ex2);
	// 	}
	// }

	/**
	 * Find an {@code @MessageExceptionHandler} method for the given exception.
	 * The default implementation searches methods in the class hierarchy of the
	 * HandlerMethod first and if not found, it continues searching for additional
	 * {@code @MessageExceptionHandler} methods among the configured
	 * {@linkplain hunt.framework.messaging.handler.MessagingAdviceBean
	 * MessagingAdviceBean}, if any.
	 * @param handlerMethod the method where the exception was raised
	 * @param exception the raised exception
	 * @return a method to handle the exception, or {@code null}
	 * @since 4.2
	 */
	
	// protected InvocableHandlerMethod getExceptionHandlerMethod(HandlerMethod handlerMethod, Exception exception) {
	// 	version(HUNT_DEBUG) {
	// 		trace("Searching methods to handle " ~ exception.TypeUtils.getSimpleName(typeid(this)));
	// 	}
	// 	Class<?> beanType = handlerMethod.getBeanType();
	// 	AbstractExceptionHandlerMethodResolver resolver = this.exceptionHandlerCache.get(beanType);
	// 	if (resolver is null) {
	// 		resolver = createExceptionHandlerMethodResolverFor(beanType);
	// 		this.exceptionHandlerCache.put(beanType, resolver);
	// 	}
	// 	Method method = resolver.resolveMethod(exception);
	// 	if (method !is null) {
	// 		return new InvocableHandlerMethod(handlerMethod.getBean(), method);
	// 	}
	// 	for (MessagingAdviceBean advice : this.exceptionHandlerAdviceCache.keySet()) {
	// 		if (advice.isApplicableToBeanType(beanType)) {
	// 			resolver = this.exceptionHandlerAdviceCache.get(advice);
	// 			method = resolver.resolveMethod(exception);
	// 			if (method !is null) {
	// 				return new InvocableHandlerMethod(advice.resolveBean(), method);
	// 			}
	// 		}
	// 	}
	// 	return null;
	// }

	// protected abstract AbstractExceptionHandlerMethodResolver createExceptionHandlerMethodResolverFor(
	// 		Class<?> beanType);


	override
	string toString() {
		return TypeUtils.getSimpleName(typeid(this)) ~ "[prefixes=" ~ getDestinationPrefixes().to!string() ~ "]";
	}


	/**
	 * A thin wrapper around a matched HandlerMethod and its matched mapping for
	 * the purpose of comparing the best match with a comparator in the context
	 * of a message.
	 */
	// private class Match {

	// 	private T mapping;

	// 	private HandlerMethod handlerMethod;

	// 	this(T mapping, HandlerMethod handlerMethod) {
	// 		this.mapping = mapping;
	// 		this.handlerMethod = handlerMethod;
	// 	}

	// 	override
	// 	string toString() {
	// 		return this.mapping.toString();
	// 	}
	// }


	// private class MatchComparator : Comparator!(Match) {

	// 	private Comparator!(T) comparator;

	// 	this(Comparator!(T) comparator) {
	// 		this.comparator = comparator;
	// 	}

	// 	override
	// 	int compare(Match match1, Match match2) {
	// 		return this.comparator.compare(match1.mapping, match2.mapping);
	// 	}
	// }


	// private class ReturnValueListenableFutureCallback : ListenableFutureCallback!(Object) {

	// 	private InvocableHandlerMethod handlerMethod;

	// 	private MessageBase message;

	// 	this(InvocableHandlerMethod handlerMethod, MessageBase message) {
	// 		this.handlerMethod = handlerMethod;
	// 		this.message = message;
	// 	}

	// 	override
	// 	void onSuccess(Object result) {
	// 		try {
	// 			MethodParameter returnType = this.handlerMethod.getAsyncReturnValueType(result);
	// 			returnValueHandlers.handleReturnValue(result, returnType, this.message);
	// 		}
	// 		catch (Throwable ex) {
	// 			handleFailure(ex);
	// 		}
	// 	}

	// 	override
	// 	void onFailure(Throwable ex) {
	// 		handleFailure(ex);
	// 	}

	// 	private void handleFailure(Throwable ex) {
	// 		Exception cause = (ex instanceof Exception ? (Exception) ex : new IllegalStateException(ex));
	// 		processHandlerMethodException(this.handlerMethod, cause, this.message);
	// 	}
	// }

}
