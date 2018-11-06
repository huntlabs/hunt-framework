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

module hunt.framework.messaging.simp.stomp.StompEncoder;


import hunt.framework.messaging.exception;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.simp.stomp.StompCommand;
import hunt.framework.messaging.simp.stomp.StompDecoder;
import hunt.framework.messaging.simp.stomp.StompHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
import hunt.framework.messaging.support.NativeMessageHeaderAccessor;

import hunt.io.ByteArrayOutputStream;
import hunt.io.BufferedOutputStream;
// import java.util.concurrent.ConcurrentHashMap;

import hunt.container;
import hunt.logging;
import hunt.lang.exception;
import hunt.string;

import std.conv;


alias DataOutputStream = BufferedOutputStream;
alias ByteArrayMap = Map!(string, byte[]);

/**
 * An encoder for STOMP frames.
 *
 * @author Andy Wilkinson
 * @author Rossen Stoyanchev
 * @since 4.0
 * @see StompDecoder
 */
class StompEncoder  {

	private enum byte LF = '\n';

	private enum byte COLON = ':';

	private enum int HEADER_KEY_CACHE_LIMIT = 32;


	private ByteArrayMap headerKeyAccessCache; // = new ConcurrentHashMap<>(HEADER_KEY_CACHE_LIMIT);

	private ByteArrayMap headerKeyUpdateCache;
	
	this() {
		headerKeyAccessCache = new HashMap!(string, byte[])(HEADER_KEY_CACHE_LIMIT);

		headerKeyUpdateCache =
			new class LinkedHashMap!(string, byte[]) {
				
				this() {
					super(HEADER_KEY_CACHE_LIMIT, 0.75f, true);
				}

				override
				protected bool removeEldestEntry(MapEntry!(string, byte[]) eldest) {
					if (size() > HEADER_KEY_CACHE_LIMIT) {
						headerKeyAccessCache.remove(eldest.getKey());
						return true;
					}
					else {
						return false;
					}
				}
			};
	}

	/**
	 * Encodes the given STOMP {@code message} into a {@code byte[]}.
	 * @param message the message to encode
	 * @return the encoded message
	 */
	byte[] encode(Message!(byte[]) message) {
		return encode(message.getHeaders(), message.getPayload());
	}

	/**
	 * Encodes the given payload and headers into a {@code byte[]}.
	 * @param headers the headers
	 * @param payload the payload
	 * @return the encoded message
	 */
	byte[] encode(Map!(string, Object) headers, byte[] payload) {
		assert(headers !is null, "'headers' is required");
		// assert(payload !is null, "'payload' is required");

		try {
			ByteArrayOutputStream baos = new ByteArrayOutputStream(128 + cast(int)payload.length);
			DataOutputStream output = new DataOutputStream(baos);

			if (SimpMessageType.HEARTBEAT == SimpMessageHeaderAccessor.getMessageType(headers)) {
				trace("Encoding heartbeat");
				output.write(StompDecoder.HEARTBEAT_PAYLOAD);
			} else {
				StompCommand command = StompHeaderAccessor.getCommand(headers);
				if (command == StompCommand.Null) {
					throw new IllegalStateException("Missing STOMP command: " ~ (cast(Object)headers).toString());
				}

				output.write( cast(byte[]) command.toString());
				output.write(LF);
				writeHeaders(command, headers, payload, output);
				output.write(LF);
				writeBody(payload, output);
				output.write(0);
			}
			output.flush();
			return baos.toByteArray();
		}
		catch (IOException ex) {
			throw new StompConversionException(
					"Failed to encode STOMP frame, headers=" ~ headers.toString(), ex);
		}
	}

	private void writeHeaders(StompCommand command, Map!(string, Object) headers, byte[] payload,
			DataOutputStream output) {
		
		Map!(string,List!(string)) nativeHeaders =
				cast(Map!(string, List!(string))) headers.get(NativeMessageHeaderAccessor.NATIVE_HEADERS);

		version(HUNT_DEBUG) {
			trace("Encoding STOMP " ~ command.toString() ~ 
				", headers=" ~ nativeHeaders.toString());
		}

		if (nativeHeaders is null) {
			return;
		}

		bool shouldEscape = (command != StompCommand.CONNECT && command != StompCommand.CONNECTED);

		foreach (string key, List!(string) values ; nativeHeaders) {
			if (command.requiresContentLength() && "content-length" == key) {
				continue;
			}

			if (StompCommand.CONNECT == command &&
					StompHeaderAccessor.STOMP_PASSCODE_HEADER == key) {
				values = Collections.singletonList(StompHeaderAccessor.getPasscode(headers));
			}

			byte[] encodedKey = encodeHeaderKey(key, shouldEscape);
			foreach (string value ; values) {
				output.write(encodedKey);
				output.write(COLON);
				output.write(encodeHeaderValue(value, shouldEscape));
				output.write(LF);
			}
		}

		if (command.requiresContentLength()) {
			size_t contentLength = payload.length;
			output.write("content-length:");
			output.write(contentLength.to!string());
			output.write(LF);
		}
	}

	private byte[] encodeHeaderKey(string input, bool canEscape) {
		string inputToUse = (canEscape ? escape(input) : input);
		if (this.headerKeyAccessCache.containsKey(inputToUse)) {
			return this.headerKeyAccessCache.get(inputToUse);
		}
		synchronized (this.headerKeyUpdateCache) {
			byte[] bytes = this.headerKeyUpdateCache.get(inputToUse);
			if (bytes is null) {
				bytes = cast(byte[])inputToUse.dup;
				this.headerKeyAccessCache.put(inputToUse, bytes);
				this.headerKeyUpdateCache.put(inputToUse, bytes);
			}
			return bytes;
		}
	}

	private byte[] encodeHeaderValue(string input, bool canEscape) {
		string inputToUse = (canEscape ? escape(input) : input);
		return cast(byte[])inputToUse.dup;
	}

	/**
	 * See STOMP Spec 1.2:
	 * <a href="http://stomp.github.io/stomp-specification-1.2.html#Value_Encoding">"Value Encoding"</a>.
	 */
	private string escape(string inString) {
		StringBuilder sb = null;
		for (int i = 0; i < inString.length; i++) {
			char c = inString.charAt(i);
			if (c == '\\') {
				sb = getStringBuilder(sb, inString, i);
				sb.append("\\\\");
			}
			else if (c == ':') {
				sb = getStringBuilder(sb, inString, i);
				sb.append("\\c");
			}
			else if (c == '\n') {
				sb = getStringBuilder(sb, inString, i);
				sb.append("\\n");
			}
			else if (c == '\r') {
				sb = getStringBuilder(sb, inString, i);
				sb.append("\\r");
			}
			else if (sb !is null){
				sb.append(c);
			}
		}
		return (sb !is null ? sb.toString() : inString);
	}

	private StringBuilder getStringBuilder(StringBuilder sb, string inString, int i) {
		if (sb is null) {
			sb = new StringBuilder(inString.length);
			sb.append(inString.substring(0, i));
		}
		return sb;
	}

	private void writeBody(byte[] payload, DataOutputStream output) {
		output.write(payload);
	}

}
