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

module hunt.framework.messaging.simp.annotation.PrincipalMethodArgumentResolver;

// import hunt.security.Principal;

// import hunt.framework.core.MethodParameter;
// import hunt.framework.messaging.Message;
// import hunt.framework.messaging.handler.invocation.HandlerMethodArgumentResolver;
// import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;

// /**
//  * {@link HandlerMethodArgumentResolver} to a {@link Principal}.
//  *
//  * @author Rossen Stoyanchev
//  * @since 4.0
//  */
// public class PrincipalMethodArgumentResolver implements HandlerMethodArgumentResolver {

// 	override
// 	bool supportsParameter(MethodParameter parameter) {
// 		Class<?> paramType = parameter.getParameterType();
// 		return Principal.class.isAssignableFrom(paramType);
// 	}

// 	override
// 	public Object resolveArgument(MethodParameter parameter, MessageBase message) throws Exception {
// 		Principal user = SimpMessageHeaderAccessor.getUser(message.getHeaders());
// 		if (user is null) {
// 			throw new MissingSessionUserException(message);
// 		}
// 		return user;
// 	}

// }
