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

module hunt.framework.messaging.simp.stomp;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import hunt.container.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import hunt.container.Map;
import java.util.Map.Entry;
import java.util.concurrent.ConcurrentHashMap;

import hunt.logging;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.simp.SimpLogging;
import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
import hunt.framework.messaging.support.NativeMessageHeaderAccessor;
import org.springframework.util.Assert;

/**
 * An encoder for STOMP frames.
 *
 * @author Andy Wilkinson
 * @author Rossen Stoyanchev
 * @since 4.0
 * @see StompDecoder
 */
public class StompEncoder  {

	private static final byte LF = '\n';

	private static final byte COLON = ':';



	private static final int HEADER_KEY_CACHE_LIMIT = 32;


	private final Map<string, byte[]> headerKeyAccessCache = new ConcurrentHashMap<>(HEADER_KEY_CACHE_LIMIT);

	
	private final Map<string, byte[]> headerKeyUpdateCache =
			new LinkedHashMap<string, byte[]>(HEADER_KEY_CACHE_LIMIT, 0.75f, true) {
				override
				protected  removeEldestEntry(Map.Entry<string, byte[]> eldest) {
					if (size() > HEADER_KEY_CACHE_LIMIT) {
						headerKeyAccessCache.remove(eldest.getKey());
						return true;
					}
					else {
						return false;
					}
				}
			};


	/**
	 * Encodes the given STOMP {@code message} into a {@code byte[]}.
	 * @param message the message to encode
	 * @return the encoded message
	 */
	public byte[] encode(Message<byte[]> message) {
		return encode(message.getHeaders(), message.getPayload());
	}

	/**
	 * Encodes the given payload and headers into a {@code byte[]}.
	 * @param headers the headers
	 * @param payload the payload
	 * @return the encoded message
	 */
	public byte[] encode(Map!(string, Object) headers, byte[] payload) {
		Assert.notNull(headers, "'headers' is required");
		Assert.notNull(payload, "'payload' is required");

		try {
			ByteArrayOutputStream baos = new ByteArrayOutputStream(128 + payload.length);
			DataOutputStream output = new DataOutputStream(baos);

			if (SimpMessageType.HEARTBEAT.equals(SimpMessageHeaderAccessor.getMessageType(headers))) {
				logger.trace("Encoding heartbeat");
				output.write(StompDecoder.HEARTBEAT_PAYLOAD);
			}

			else {
				StompCommand command = StompHeaderAccessor.getCommand(headers);
				if (command is null) {
					throw new IllegalStateException("Missing STOMP command: " ~ headers);
				}

				output.write(command.toString().getBytes(StandardCharsets.UTF_8));
				output.write(LF);
				writeHeaders(command, headers, payload, output);
				output.write(LF);
				writeBody(payload, output);
				output.write((byte) 0);
			}

			return baos.toByteArray();
		}
		catch (IOException ex) {
			throw new StompConversionException("Failed to encode STOMP frame, headers=" ~ headers,  ex);
		}
	}

	private void writeHeaders(StompCommand command, Map!(string, Object) headers, byte[] payload,
			DataOutputStream output) throws IOException {

		
		Map<string,List!(string)> nativeHeaders =
				(Map<string, List!(string)>) headers.get(NativeMessageHeaderAccessor.NATIVE_HEADERS);

		if (logger.isTraceEnabled()) {
			logger.trace("Encoding STOMP " ~ command ~ ", headers=" ~ nativeHeaders);
		}

		if (nativeHeaders is null) {
			return;
		}

		 shouldEscape = (command != StompCommand.CONNECT && command != StompCommand.CONNECTED);

		for (Entry<string, List!(string)> entry : nativeHeaders.entrySet()) {
			if (command.requiresContentLength() && "content-length".equals(entry.getKey())) {
				continue;
			}

			List!(string) values = entry.getValue();
			if (StompCommand.CONNECT.equals(command) &&
					StompHeaderAccessor.STOMP_PASSCODE_HEADER.equals(entry.getKey())) {
				values = Collections.singletonList(StompHeaderAccessor.getPasscode(headers));
			}

			byte[] encodedKey = encodeHeaderKey(entry.getKey(), shouldEscape);
			for (string value : values) {
				output.write(encodedKey);
				output.write(COLON);
				output.write(encodeHeaderValue(value, shouldEscape));
				output.write(LF);
			}
		}

		if (command.requiresContentLength()) {
			int contentLength = payload.length;
			output.write("content-length:".getBytes(StandardCharsets.UTF_8));
			output.write(Integer.toString(contentLength).getBytes(StandardCharsets.UTF_8));
			output.write(LF);
		}
	}

	private byte[] encodeHeaderKey(string input,  escape) {
		string inputToUse = (escape ? escape(input) : input);
		if (this.headerKeyAccessCache.containsKey(inputToUse)) {
			return this.headerKeyAccessCache.get(inputToUse);
		}
		synchronized (this.headerKeyUpdateCache) {
			byte[] bytes = this.headerKeyUpdateCache.get(inputToUse);
			if (bytes is null) {
				bytes = inputToUse.getBytes(StandardCharsets.UTF_8);
				this.headerKeyAccessCache.put(inputToUse, bytes);
				this.headerKeyUpdateCache.put(inputToUse, bytes);
			}
			return bytes;
		}
	}

	private byte[] encodeHeaderValue(string input,  escape) {
		string inputToUse = (escape ? escape(input) : input);
		return inputToUse.getBytes(StandardCharsets.UTF_8);
	}

	/**
	 * See STOMP Spec 1.2:
	 * <a href="http://stomp.github.io/stomp-specification-1.2.html#Value_Encoding">"Value Encoding"</a>.
	 */
	private string escape(string inString) {
		StringBuilder sb = null;
		for (int i = 0; i < inString.length(); i++) {
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
			sb = new StringBuilder(inString.length());
			sb.append(inString.substring(0, i));
		}
		return sb;
	}

	private void writeBody(byte[] payload, DataOutputStream output) throws IOException {
		output.write(payload);
	}

}
