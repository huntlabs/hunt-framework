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

module hunt.framework.websocket.messaging.WebSocketAnnotationMethodMessageHandler;

import hunt.framework.context.ApplicationContext;
// import hunt.framework.core.annotation.AnnotationAwareOrderComparator;
import hunt.framework.websocket.WebSocketController;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;
import hunt.stomp.MessagingException;

// import hunt.stomp.handler.MessagingAdviceBean;
// import hunt.stomp.handler.annotation.support.AnnotationExceptionHandlerMethodResolver;
import hunt.stomp.simp.SimpMessageSendingOperations;
import hunt.stomp.simp.annotation.SimpAnnotationMethodMessageHandler;
// import hunt.framework.web.method.ControllerAdviceBean;

import hunt.logging;

/**
 * A sub-class of {@link SimpAnnotationMethodMessageHandler} to provide support
 * for {@link hunt.framework.web.bind.annotation.ControllerAdvice
 * ControllerAdvice} with global {@code @MessageExceptionHandler} methods.
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 */
class WebSocketAnnotationMethodMessageHandler : SimpAnnotationMethodMessageHandler {

	this(SubscribableChannel clientInChannel,
			MessageChannel clientOutChannel, SimpMessageSendingOperations brokerTemplate) {

		super(clientInChannel, clientOutChannel, brokerTemplate);
	}


	override
	void afterPropertiesSet() {
		initControllerAdviceCache();
		super.afterPropertiesSet();
	}

	// ApplicationContext getApplicationContext() {
	// 	return this.applicationContext;
	// }

	private void initControllerAdviceCache() {
		// ApplicationContext context = getApplicationContext();
		// if (context is null) {
		// 	return;
		// }
		import hunt.lang.exception;
		implementationMissing(false);
		version(HUNT_DEBUG) {
			// trace("Looking for @MessageExceptionHandler mappings: " ~ (cast(Object)context).toString());
		}
		// TODO: Tasks pending completion -@zxp at 10/30/2018, 2:39:18 PM
		// 
		// ControllerAdviceBean[] beans = ControllerAdviceBean.findAnnotatedBeans(context);
		// AnnotationAwareOrderComparator.sort(beans);
		// initMessagingAdviceCache(MessagingControllerAdviceBean.createFromList(beans));
	}

	override protected void handleMessageInternal(MessageBase message, string lookupDestination) {
		// FIXME: Needing refactor or cleanup -@zxp at 11/13/2018, 3:07:59 PM
		// more tests
		try {
			WebSocketControllerHelper.invoke(lookupDestination, message, 
				(Object returnValue, TypeInfo returnType, string[] destinations) {
				handleReturnValue(returnValue, returnType, message, destinations);
			});
		}
		catch (Exception ex) {
			warning(ex.msg);
			// processHandlerMethodException(handlerMethod, ex, message);
		}
		catch (Throwable ex) {
			warning(ex.msg);
			Exception handlingException = new MessageHandlingException(message, 
				"Unexpected handler method invocation error", ex);
		}
	}

	// private void initMessagingAdviceCache(MessagingAdviceBean[] beans) {
	// 	if (beans is null) {
	// 		return;
	// 	}
	// 	foreach (MessagingAdviceBean bean ; beans) {
	// 		TypeInfo_Class type = bean.getBeanType();
	// 		if (type !is null) {
	// 			AnnotationExceptionHandlerMethodResolver resolver = new AnnotationExceptionHandlerMethodResolver(type);
	// 			if (resolver.hasExceptionMappings()) {
	// 				registerExceptionHandlerAdvice(bean, resolver);
	// 				version(HUNT_DEBUG) {
	// 					trace("Detected @MessageExceptionHandler methods in " ~ bean);
	// 				}
	// 			}
	// 		}
	// 	}
	// }

}


/**
 * Adapt ControllerAdviceBean to MessagingAdviceBean.
 */
// private final class MessagingControllerAdviceBean : MessagingAdviceBean {

// 	private final ControllerAdviceBean adviceBean;

// 	private this(ControllerAdviceBean adviceBean) {
// 		this.adviceBean = adviceBean;
// 	}

// 	static MessagingAdviceBean[] createFromList(ControllerAdviceBean[] beans) {
// 		MessagingAdviceBean[] result;
// 		foreach (ControllerAdviceBean bean ; beans) {
// 			result ~= new MessagingControllerAdviceBean(bean);
// 		}
// 		return result;
// 	}

// 	override
	
// 	TypeInfo_Class getBeanType() {
// 		return this.adviceBean.getBeanType();
// 	}

// 	override
// 	Object resolveBean() {
// 		return this.adviceBean.resolveBean();
// 	}

// 	override
// 	boolisApplicableToBeanType(TypeInfo_Class beanType) {
// 		return this.adviceBean.isApplicableToBeanType(beanType);
// 	}

// 	override
// 	int getOrder() {
// 		return this.adviceBean.getOrder();
// 	}
// }
