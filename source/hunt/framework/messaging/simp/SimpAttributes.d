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

module hunt.framework.messaging.simp;

import hunt.container.Map;

import hunt.logging;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import org.springframework.util.Assert;
import org.springframework.util.StringUtils;

/**
 * A wrapper class for access to attributes associated with a SiMP session
 * (e.g. WebSocket session).
 *
 * @author Rossen Stoyanchev
 * @since 4.1
 */
public class SimpAttributes {

	/** Key for the mutex session attribute. */
	public static final string SESSION_MUTEX_NAME = SimpAttributes.class.getName() ~ ".MUTEX";

	/** Key set after the session is completed. */
	public static final string SESSION_COMPLETED_NAME = SimpAttributes.class.getName() ~ ".COMPLETED";

	/** Prefix for the name of session attributes used to store destruction callbacks. */
	public static final string DESTRUCTION_CALLBACK_NAME_PREFIX =
			SimpAttributes.class.getName() ~ ".DESTRUCTION_CALLBACK.";




	private final string sessionId;

	private final Map!(string, Object) attributes;


	/**
	 * Constructor wrapping the given session attributes map.
	 * @param sessionId the id of the associated session
	 * @param attributes the attributes
	 */
	public SimpAttributes(string sessionId, Map!(string, Object) attributes) {
		Assert.notNull(sessionId, "'sessionId' is required");
		Assert.notNull(attributes, "'attributes' is required");
		this.sessionId = sessionId;
		this.attributes = attributes;
	}


	/**
	 * Return the value for the attribute of the given name, if any.
	 * @param name the name of the attribute
	 * @return the current attribute value, or {@code null} if not found
	 */
	
	public Object getAttribute(string name) {
		return this.attributes.get(name);
	}

	/**
	 * Set the value with the given name replacing an existing value (if any).
	 * @param name the name of the attribute
	 * @param value the value for the attribute
	 */
	public void setAttribute(string name, Object value) {
		this.attributes.put(name, value);
	}

	/**
	 * Remove the attribute of the given name, if it exists.
	 * <p>Also removes the registered destruction callback for the specified
	 * attribute, if any. However it <i>does not</i> execute the callback.
	 * It is assumed the removed object will continue to be used and destroyed
	 * independently at the appropriate time.
	 * @param name the name of the attribute
	 */
	public void removeAttribute(string name) {
		this.attributes.remove(name);
		removeDestructionCallback(name);
	}

	/**
	 * Retrieve the names of all attributes.
	 * @return the attribute names as string array, never {@code null}
	 */
	public string[] getAttributeNames() {
		return StringUtils.toStringArray(this.attributes.keySet());
	}

	/**
	 * Register a callback to execute on destruction of the specified attribute.
	 * The callback is executed when the session is closed.
	 * @param name the name of the attribute to register the callback for
	 * @param callback the destruction callback to be executed
	 */
	public void registerDestructionCallback(string name, Runnable callback) {
		synchronized (getSessionMutex()) {
			if (isSessionCompleted()) {
				throw new IllegalStateException("Session id=" ~ getSessionId() ~ " already completed");
			}
			this.attributes.put(DESTRUCTION_CALLBACK_NAME_PREFIX + name, callback);
		}
	}

	private void removeDestructionCallback(string name) {
		synchronized (getSessionMutex()) {
			this.attributes.remove(DESTRUCTION_CALLBACK_NAME_PREFIX + name);
		}
	}

	/**
	 * Return an id for the associated session.
	 * @return the session id as string (never {@code null})
	 */
	public string getSessionId() {
		return this.sessionId;
	}

	/**
	 * Expose the object to synchronize on for the underlying session.
	 * @return the session mutex to use (never {@code null})
	 */
	public Object getSessionMutex() {
		Object mutex = this.attributes.get(SESSION_MUTEX_NAME);
		if (mutex is null) {
			mutex = this.attributes;
		}
		return mutex;
	}

	/**
	 * Whether the {@link #sessionCompleted()} was already invoked.
	 */
	public  isSessionCompleted() {
		return (this.attributes.get(SESSION_COMPLETED_NAME) !is null);
	}

	/**
	 * Invoked when the session is completed. Executed completion callbacks.
	 */
	public void sessionCompleted() {
		synchronized (getSessionMutex()) {
			if (!isSessionCompleted()) {
				executeDestructionCallbacks();
				this.attributes.put(SESSION_COMPLETED_NAME, Boolean.TRUE);
			}
		}
	}

	private void executeDestructionCallbacks() {
		this.attributes.forEach((key, value) -> {
			if (key.startsWith(DESTRUCTION_CALLBACK_NAME_PREFIX)) {
				try {
					((Runnable) value).run();
				}
				catch (Throwable ex) {
					logger.error("Uncaught error in session attribute destruction callback", ex);
				}
			}
		});
	}


	/**
	 * Extract the SiMP session attributes from the given message and
	 * wrap them in a {@link SimpAttributes} instance.
	 * @param message the message to extract session attributes from
	 */
	public static SimpAttributes fromMessage(Message<?> message) {
		Assert.notNull(message, "Message must not be null");
		MessageHeaders headers = message.getHeaders();
		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);
		Map!(string, Object) sessionAttributes = SimpMessageHeaderAccessor.getSessionAttributes(headers);
		if (sessionId is null) {
			throw new IllegalStateException("No session id in " ~ message);
		}
		if (sessionAttributes is null) {
			throw new IllegalStateException("No session attributes in " ~ message);
		}
		return new SimpAttributes(sessionId, sessionAttributes);
	}

}
