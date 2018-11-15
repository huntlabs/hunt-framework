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

module hunt.framework.websocket.messaging.StompSubProtocolErrorHandler;

import hunt.framework.websocket.messaging.SubProtocolErrorHandler;

import hunt.stomp.Message;
import hunt.stomp.simp.stomp.StompCommand;
import hunt.stomp.simp.stomp.StompHeaderAccessor;
import hunt.stomp.support.MessageBuilder;
import hunt.stomp.support.MessageHeaderAccessor;

/**
 * A {@link SubProtocolErrorHandler} for use with STOMP.
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 */
class StompSubProtocolErrorHandler : SubProtocolErrorHandler!(byte[]) {

	private enum byte[] EMPTY_PAYLOAD = [];


	override
	Message!(byte[]) handleClientMessageProcessingError(Message!(byte[]) clientMessage, Throwable ex) {
		StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.ERROR);
		accessor.setMessage(ex.msg);
		accessor.setLeaveMutable(true);

		StompHeaderAccessor clientHeaderAccessor = null;
		if (clientMessage !is null) {
			clientHeaderAccessor = MessageHeaderAccessor.getAccessor!(StompHeaderAccessor)(clientMessage);
			if (clientHeaderAccessor !is null) {
				string receiptId = clientHeaderAccessor.getReceipt();
				if (receiptId !is null) {
					accessor.setReceiptId(receiptId);
				}
			}
		}

		return handleInternal(accessor, EMPTY_PAYLOAD, ex, clientHeaderAccessor);
	}

	override
	Message!(byte[]) handleErrorMessageToClient(Message!(byte[]) errorMessage) {
		StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!(StompHeaderAccessor)(errorMessage);
		assert(accessor, "No StompHeaderAccessor");
		if (!accessor.isMutable()) {
			accessor = StompHeaderAccessor.wrap(errorMessage);
		}
		return handleInternal(accessor, errorMessage.getPayload(), null, null);
	}

	protected Message!(byte[]) handleInternal(StompHeaderAccessor errorHeaderAccessor, byte[] errorPayload,
			Throwable cause, StompHeaderAccessor clientHeaderAccessor) {

		return MessageHelper.createMessage(errorPayload, errorHeaderAccessor.getMessageHeaders());
	}

}
