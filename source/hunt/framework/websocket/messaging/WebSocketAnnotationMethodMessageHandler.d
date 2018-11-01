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

import hunt.framework.messaging.MessageChannel;

// import hunt.framework.messaging.handler.MessagingAdviceBean;
// import hunt.framework.messaging.handler.annotation.support.AnnotationExceptionHandlerMethodResolver;
import hunt.framework.messaging.simp.SimpMessageSendingOperations;
import hunt.framework.messaging.simp.annotation.SimpAnnotationMethodMessageHandler;
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

	private void initControllerAdviceCache() {
		ApplicationContext context = getApplicationContext();
		if (context is null) {
			return;
		}
		version(HUNT_DEBUG) {
			trace("Looking for @MessageExceptionHandler mappings: " ~ (cast(Object)context).toString());
		}
		// TODO: Tasks pending completion -@zxp at 10/30/2018, 2:39:18 PM
		// 
		// ControllerAdviceBean[] beans = ControllerAdviceBean.findAnnotatedBeans(context);
		// AnnotationAwareOrderComparator.sort(beans);
		// initMessagingAdviceCache(MessagingControllerAdviceBean.createFromList(beans));
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
