/*
 * Copyright 2002-2017 the original author or authors.
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

module hunt.framework.messaging.core.BeanFactoryMessageChannelDestinationResolver;

import hunt.framework.messaging.core.DestinationResolver;

// import hunt.framework.beans.BeansException;
// import hunt.framework.beans.factory.BeanFactory;
// import hunt.framework.beans.factory.BeanFactoryAware;

import hunt.framework.messaging.MessageChannel;


/**
 * An implementation of {@link DestinationResolver} that interprets a destination
 * name as the bean name of a {@link MessageChannel} and looks up the bean in
 * the configured {@link BeanFactory}.
 *
 * @author Mark Fisher
 * @since 4.0
 */
class BeanFactoryMessageChannelDestinationResolver(T)
		: DestinationResolver!(MessageChannel!(T)) { // , BeanFactoryAware 

	// private BeanFactory beanFactory;


	// /**
	//  * A default constructor that can be used when the resolver itself is configured
	//  * as a Spring bean and will have the {@code BeanFactory} injected as a result
	//  * of ing having implemented {@link BeanFactoryAware}.
	//  */
	// BeanFactoryMessageChannelDestinationResolver() {
	// }

	// /**
	//  * A constructor that accepts a {@link BeanFactory} useful if instantiating this
	//  * resolver manually rather than having it defined as a Spring-managed bean.
	//  * @param beanFactory the bean factory to perform lookups against
	//  */
	// BeanFactoryMessageChannelDestinationResolver(BeanFactory beanFactory) {
	// 	assert(beanFactory, "beanFactory must not be null");
	// 	this.beanFactory = beanFactory;
	// }


	// override
	// void setBeanFactory(BeanFactory beanFactory) {
	// 	this.beanFactory = beanFactory;
	// }


	// override
	// MessageChannel resolveDestination(string name) {
	// 	assert(this.beanFactory !is null, "No BeanFactory configured");
	// 	try {
	// 		return this.beanFactory.getBean(name, MessageChannel.class);
	// 	}
	// 	catch (BeansException ex) {
	// 		throw new DestinationResolutionException(
	// 				"Failed to find MessageChannel bean with name '" ~ name ~ "'", ex);
	// 	}
	// }

}
