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

module hunt.framework.messaging.simp.stomp.ReactorNettyTcpStompClient;

// import hunt.framework.messaging.tcp.TcpOperations;
// import hunt.framework.messaging.tcp.reactor.ReactorNettyTcpClient;

// import hunt.framework.util.concurrent.ListenableFuture;

// /**
//  * A STOMP over TCP client that uses {@link ReactorNettyTcpClient}.
//  *
//  * @author Rossen Stoyanchev
//  * @since 5.0
//  */
// class ReactorNettyTcpStompClient : StompClientSupport {

// 	private final TcpOperations!(byte[]) tcpClient;


// 	/**
// 	 * Create an instance with host "127.0.0.1" and port 61613.
// 	 */
// 	this() {
// 		this("127.0.0.1", 61613);
// 	}

// 	/**
// 	 * Create an instance with the given host and port.
// 	 * @param host the host
// 	 * @param port the port
// 	 */
// 	ReactorNettyTcpStompClient(string host, int port) {
// 		this.tcpClient = initTcpClient(host, port);
// 	}

// 	/**
// 	 * Create an instance with a pre-configured TCP client.
// 	 * @param tcpClient the client to use
// 	 */
// 	ReactorNettyTcpStompClient(TcpOperations!(byte[]) tcpClient) {
// 		assert(tcpClient, "'tcpClient' is required");
// 		this.tcpClient = tcpClient;
// 	}

// 	private static ReactorNettyTcpClient!(byte[]) initTcpClient(string host, int port) {
// 		ReactorNettyTcpClient!(byte[]) client = new ReactorNettyTcpClient<>(host, port, new StompReactorNettyCodec());
// 		client.setLogger(SimpLogging.forLog(client.getLogger()));
// 		return client;
// 	}


// 	/**
// 	 * Connect and notify the given {@link StompSessionHandler} when connected
// 	 * on the STOMP level.
// 	 * @param handler the handler for the STOMP session
// 	 * @return a ListenableFuture for access to the session when ready for use
// 	 */
// 	ListenableFuture!(StompSession) connect(StompSessionHandler handler) {
// 		return connect(null, handler);
// 	}

// 	/**
// 	 * An overloaded version of {@link #connect(StompSessionHandler)} that
// 	 * accepts headers to use for the STOMP CONNECT frame.
// 	 * @param connectHeaders headers to add to the CONNECT frame
// 	 * @param handler the handler for the STOMP session
// 	 * @return a ListenableFuture for access to the session when ready for use
// 	 */
// 	ListenableFuture!(StompSession) connect(StompHeaders connectHeaders, StompSessionHandler handler) {
// 		ConnectionHandlingStompSession session = createSession(connectHeaders, handler);
// 		this.tcpClient.connect(session);
// 		return session.getSessionFuture();
// 	}

// 	/**
// 	 * Shut down the client and release resources.
// 	 */
// 	void shutdown() {
// 		this.tcpClient.shutdown();
// 	}

// 	override
// 	string toString() {
// 		return "ReactorNettyTcpStompClient[" ~ this.tcpClient ~ "]";
// 	}
// }
