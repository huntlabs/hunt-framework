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

module hunt.framework.messaging.simp.annotation.SendToMethodReturnValueHandler;

// import java.lang.annotation.Annotation;
// import hunt.security.Principal;
// import hunt.container.Collections;
// import hunt.container.Map;

// import hunt.framework.core.MethodParameter;
// import hunt.framework.core.annotation.AnnotatedElementUtils;
// import hunt.framework.core.annotation.AnnotationUtils;

// import hunt.framework.messaging.Message;
// import hunt.framework.messaging.MessageChannel;
// import hunt.framework.messaging.MessageHeaders;
// import hunt.framework.messaging.handler.DestinationPatternsMessageCondition;
// import hunt.framework.messaging.handler.annotation.SendTo;
// import hunt.framework.messaging.handler.annotation.support.DestinationVariableMethodArgumentResolver;
// import hunt.framework.messaging.handler.invocation.HandlerMethodReturnValueHandler;
// import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
// import hunt.framework.messaging.simp.SimpMessageSendingOperations;
// import hunt.framework.messaging.simp.SimpMessageType;
// import hunt.framework.messaging.simp.SimpMessagingTemplate;
// import hunt.framework.messaging.simp.annotation.SendToUser;
// import hunt.framework.messaging.simp.user.DestinationUserNameProvider;
// 

// import hunt.framework.util.ObjectUtils;
// import hunt.framework.util.PropertyPlaceholderHelper;
// import hunt.framework.util.PropertyPlaceholderHelper.PlaceholderResolver;
// import hunt.framework.util.StringUtils;

// /**
//  * A {@link HandlerMethodReturnValueHandler} for sending to destinations specified in a
//  * {@link SendTo} or {@link SendToUser} method-level annotations.
//  *
//  * <p>The value returned from the method is converted, and turned to a {@link Message} and
//  * sent through the provided {@link MessageChannel}. The message is then enriched with the
//  * session id of the input message as well as the destination from the annotation(s).
//  * If multiple destinations are specified, a copy of the message is sent to each destination.
//  *
//  * @author Rossen Stoyanchev
//  * @author Sebastien Deleuze
//  * @since 4.0
//  */
// class SendToMethodReturnValueHandler : HandlerMethodReturnValueHandler {

// 	private SimpMessageSendingOperations messagingTemplate;

// 	private bool annotationRequired;

// 	private string defaultDestinationPrefix = "/topic";

// 	private string defaultUserDestinationPrefix = "/queue";

// 	private PropertyPlaceholderHelper placeholderHelper;
	
// 	private MessageHeaderInitializer headerInitializer;


// 	this(SimpMessageSendingOperations messagingTemplate, bool annotationRequired) {
// 		assert(messagingTemplate, "'messagingTemplate' must not be null");
// 		this.messagingTemplate = messagingTemplate;
// 		this.annotationRequired = annotationRequired;
// 		placeholderHelper = new PropertyPlaceholderHelper("{", "}", null, false);
// 	}


// 	/**
// 	 * Configure a default prefix to add to message destinations in cases where a method
// 	 * is not annotated with {@link SendTo @SendTo} or does not specify any destinations
// 	 * through the annotation's value attribute.
// 	 * <p>By default, the prefix is set to "/topic".
// 	 */
// 	void setDefaultDestinationPrefix(string defaultDestinationPrefix) {
// 		this.defaultDestinationPrefix = defaultDestinationPrefix;
// 	}

// 	/**
// 	 * Return the configured default destination prefix.
// 	 * @see #setDefaultDestinationPrefix(string)
// 	 */
// 	string getDefaultDestinationPrefix() {
// 		return this.defaultDestinationPrefix;
// 	}

// 	/**
// 	 * Configure a default prefix to add to message destinations in cases where a
// 	 * method is annotated with {@link SendToUser @SendToUser} but does not specify
// 	 * any destinations through the annotation's value attribute.
// 	 * <p>By default, the prefix is set to "/queue".
// 	 */
// 	void setDefaultUserDestinationPrefix(string prefix) {
// 		this.defaultUserDestinationPrefix = prefix;
// 	}

// 	/**
// 	 * Return the configured default user destination prefix.
// 	 * @see #setDefaultUserDestinationPrefix(string)
// 	 */
// 	string getDefaultUserDestinationPrefix() {
// 		return this.defaultUserDestinationPrefix;
// 	}

// 	/**
// 	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of all
// 	 * messages sent to the client outbound channel.
// 	 * <p>By default this property is not set.
// 	 */
// 	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
// 		this.headerInitializer = headerInitializer;
// 	}

// 	/**
// 	 * Return the configured header initializer.
// 	 */
	
// 	MessageHeaderInitializer getHeaderInitializer() {
// 		return this.headerInitializer;
// 	}


// 	override
// 	bool supportsReturnType(MethodParameter returnType) {
// 		return (returnType.hasMethodAnnotation(SendTo.class) ||
// 				AnnotatedElementUtils.hasAnnotation(returnType.getDeclaringClass(), SendTo.class) ||
// 				returnType.hasMethodAnnotation(SendToUser.class) ||
// 				AnnotatedElementUtils.hasAnnotation(returnType.getDeclaringClass(), SendToUser.class) ||
// 				!this.annotationRequired);
// 	}

// 	override
// 	void handleReturnValue(Object returnValue, MethodParameter returnType, MessageBase message) {

// 		if (returnValue is null) {
// 			return;
// 		}

// 		MessageHeaders headers = message.getHeaders();
// 		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);
// 		DestinationHelper destinationHelper = getDestinationHelper(headers, returnType);

// 		SendToUser sendToUser = destinationHelper.getSendToUser();
// 		if (sendToUser !is null) {
// 			 broadcast = sendToUser.broadcast();
// 			string user = getUserName(message, headers);
// 			if (user is null) {
// 				if (sessionId is null) {
// 					throw new MissingSessionUserException(message);
// 				}
// 				user = sessionId;
// 				broadcast = false;
// 			}
// 			string[] destinations = getTargetDestinations(sendToUser, message, this.defaultUserDestinationPrefix);
// 			for (string destination : destinations) {
// 				destination = destinationHelper.expandTemplateVars(destination);
// 				if (broadcast) {
// 					this.messagingTemplate.convertAndSendToUser(
// 							user, destination, returnValue, createHeaders(null, returnType));
// 				}
// 				else {
// 					this.messagingTemplate.convertAndSendToUser(
// 							user, destination, returnValue, createHeaders(sessionId, returnType));
// 				}
// 			}
// 		}

// 		SendTo sendTo = destinationHelper.getSendTo();
// 		if (sendTo !is null || sendToUser is null) {
// 			string[] destinations = getTargetDestinations(sendTo, message, this.defaultDestinationPrefix);
// 			for (string destination : destinations) {
// 				destination = destinationHelper.expandTemplateVars(destination);
// 				this.messagingTemplate.convertAndSend(destination, returnValue, createHeaders(sessionId, returnType));
// 			}
// 		}
// 	}

// 	private DestinationHelper getDestinationHelper(MessageHeaders headers, MethodParameter returnType) {
// 		SendToUser m1 = AnnotatedElementUtils.findMergedAnnotation(returnType.getExecutable(), SendToUser.class);
// 		SendTo m2 = AnnotatedElementUtils.findMergedAnnotation(returnType.getExecutable(), SendTo.class);
// 		if ((m1 !is null && !ObjectUtils.isEmpty(m1.value())) || (m2 !is null && !ObjectUtils.isEmpty(m2.value()))) {
// 			return new DestinationHelper(headers, m1, m2);
// 		}

// 		SendToUser c1 = AnnotatedElementUtils.findMergedAnnotation(returnType.getDeclaringClass(), SendToUser.class);
// 		SendTo c2 = AnnotatedElementUtils.findMergedAnnotation(returnType.getDeclaringClass(), SendTo.class);
// 		if ((c1 !is null && !ObjectUtils.isEmpty(c1.value())) || (c2 !is null && !ObjectUtils.isEmpty(c2.value()))) {
// 			return new DestinationHelper(headers, c1, c2);
// 		}

// 		return (m1 !is null || m2 !is null ?
// 				new DestinationHelper(headers, m1, m2) : new DestinationHelper(headers, c1, c2));
// 	}

	
// 	protected string getUserName(MessageBase message, MessageHeaders headers) {
// 		Principal principal = SimpMessageHeaderAccessor.getUser(headers);
// 		if (principal !is null) {
// 			return (principal instanceof DestinationUserNameProvider ?
// 					((DestinationUserNameProvider) principal).getDestinationUserName() : principal.getName());
// 		}
// 		return null;
// 	}

// 	protected string[] getTargetDestinations(Annotation annotation, MessageBase message, string defaultPrefix) {
// 		if (annotation !is null) {
// 			string[] value = (string[]) AnnotationUtils.getValue(annotation);
// 			if (!ObjectUtils.isEmpty(value)) {
// 				return value;
// 			}
// 		}

// 		string name = DestinationPatternsMessageCondition.LOOKUP_DESTINATION_HEADER;
// 		string destination = (string) message.getHeaders().get(name);
// 		if (!StringUtils.hasText(destination)) {
// 			throw new IllegalStateException("No lookup destination header in " ~ message);
// 		}

// 		return (destination.startsWith("/") ?
// 				new string[] {defaultPrefix + destination} : new string[] {defaultPrefix + '/' + destination});
// 	}

// 	private MessageHeaders createHeaders(string sessionId, MethodParameter returnType) {
// 		SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
// 		if (getHeaderInitializer() !is null) {
// 			getHeaderInitializer().initHeaders(headerAccessor);
// 		}
// 		if (sessionId !is null) {
// 			headerAccessor.setSessionId(sessionId);
// 		}
// 		headerAccessor.setHeader(SimpMessagingTemplate.CONVERSION_HINT_HEADER, returnType);
// 		headerAccessor.setLeaveMutable(true);
// 		return headerAccessor.getMessageHeaders();
// 	}


// 	override
// 	string toString() {
// 		return "SendToMethodReturnValueHandler [annotationRequired=" ~ this.annotationRequired ~ "]";
// 	}


// 	private class DestinationHelper {

// 		private final PlaceholderResolver placeholderResolver;

		
// 		private final SendTo sendTo;

		
// 		private final SendToUser sendToUser;


// 		DestinationHelper(MessageHeaders headers, SendToUser sendToUser, SendTo sendTo) {
// 			Map!(string, string) variables = getTemplateVariables(headers);
// 			this.placeholderResolver = variables::get;
// 			this.sendTo = sendTo;
// 			this.sendToUser = sendToUser;
// 		}

		
// 		private Map!(string, string) getTemplateVariables(MessageHeaders headers) {
// 			string name = DestinationVariableMethodArgumentResolver.DESTINATION_TEMPLATE_VARIABLES_HEADER;
// 			return (Map!(string, string)) headers.getOrDefault(name, Collections.emptyMap());
// 		}

		
// 		SendTo getSendTo() {
// 			return this.sendTo;
// 		}

		
// 		SendToUser getSendToUser() {
// 			return this.sendToUser;
// 		}

// 		string expandTemplateVars(string destination) {
// 			return placeholderHelper.replacePlaceholders(destination, this.placeholderResolver);
// 		}
// 	}

// }
