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

module hunt.framework.messaging.simp.config.ChannelRegistration;


import hunt.framework.messaging.support.ChannelInterceptor;
// import hunt.framework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * A registration class for customizing the configuration for a
 * {@link hunt.framework.messaging.MessageChannel}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class ChannelRegistration {
	
	// private TaskExecutorRegistration registration;

	private ChannelInterceptor[] interceptors;


	/**
	 * Configure the thread pool backing this message channel.
	 */
	// TaskExecutorRegistration taskExecutor() {
	// 	return taskExecutor(null);
	// }

	/**
	 * Configure the thread pool backing this message channel using a custom
	 * ThreadPoolTaskExecutor.
	 * @param taskExecutor the executor to use (or {@code null} for a default executor)
	 */
	// TaskExecutorRegistration taskExecutor(ThreadPoolTaskExecutor taskExecutor) {
	// 	if (this.registration is null) {
	// 		this.registration = (taskExecutor !is null ? new TaskExecutorRegistration(taskExecutor) :
	// 				new TaskExecutorRegistration());
	// 	}
	// 	return this.registration;
	// }

	/**
	 * Configure the given interceptors for this message channel,
	 * adding them to the channel's current list of interceptors.
	 * @since 4.3.12
	 */
	ChannelRegistration addInterceptors(ChannelInterceptor[] interceptors... ) {
		this.interceptors ~= interceptors.dup;
		return this;
	}

	/**
	 * Configure interceptors for the message channel.
	 * @deprecated as of 4.3.12, in favor of {@link #interceptors(ChannelInterceptor...)}
	 */
	// @Deprecated
	// ChannelRegistration setInterceptors(ChannelInterceptor[] interceptors... ) {
	// 	if (interceptors !is null) {
	// 		this.interceptors ~= interceptors;
	// 	}
	// 	return this;
	// }


	bool hasTaskExecutor() {
		// return (this.registration !is null);
		return false;
	}

	bool hasInterceptors() {
		return !this.interceptors.length > 0;
	}

	ChannelInterceptor[] getInterceptors() {
		return this.interceptors;
	}

}
