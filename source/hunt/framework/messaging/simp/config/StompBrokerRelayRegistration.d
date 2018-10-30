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

module hunt.framework.messaging.simp.config.StompBrokerRelayRegistration;


// import hunt.framework.messaging.MessageChannel;
// 
// import hunt.framework.messaging.simp.stomp.StompBrokerRelayMessageHandler;
// import hunt.framework.messaging.tcp.TcpOperations;


// /**
//  * Registration class for configuring a {@link StompBrokerRelayMessageHandler}.
//  *
//  * @author Rossen Stoyanchev
//  * @since 4.0
//  */
// public class StompBrokerRelayRegistration : AbstractBrokerRegistration {

// 	private string relayHost = "127.0.0.1";

// 	private int relayPort = 61613;

// 	private string clientLogin = "guest";

// 	private string clientPasscode = "guest";

// 	private string systemLogin = "guest";

// 	private string systemPasscode = "guest";

	
// 	private Long systemHeartbeatSendInterval;

	
// 	private Long systemHeartbeatReceiveInterval;

	
// 	private string virtualHost;

	
// 	private TcpOperations!(byte[]) tcpClient;

// 	private bool autoStartup = true;

	
// 	private string userDestinationBroadcast;

	
// 	private string userRegistryBroadcast;


// 	public StompBrokerRelayRegistration(SubscribableChannel clientInboundChannel,
// 			MessageChannel clientOutboundChannel, string[] destinationPrefixes) {

// 		super(clientInboundChannel, clientOutboundChannel, destinationPrefixes);
// 	}


// 	/**
// 	 * Set the STOMP message broker host.
// 	 */
// 	public StompBrokerRelayRegistration setRelayHost(string relayHost) {
// 		Assert.hasText(relayHost, "relayHost must not be empty");
// 		this.relayHost = relayHost;
// 		return this;
// 	}

// 	/**
// 	 * Set the STOMP message broker port.
// 	 */
// 	public StompBrokerRelayRegistration setRelayPort(int relayPort) {
// 		this.relayPort = relayPort;
// 		return this;
// 	}

// 	/**
// 	 * Set the login to use when creating connections to the STOMP broker on
// 	 * behalf of connected clients.
// 	 * <p>By default this is set to "guest".
// 	 */
// 	public StompBrokerRelayRegistration setClientLogin(string login) {
// 		Assert.hasText(login, "clientLogin must not be empty");
// 		this.clientLogin = login;
// 		return this;
// 	}

// 	/**
// 	 * Set the passcode to use when creating connections to the STOMP broker on
// 	 * behalf of connected clients.
// 	 * <p>By default this is set to "guest".
// 	 */
// 	public StompBrokerRelayRegistration setClientPasscode(string passcode) {
// 		Assert.hasText(passcode, "clientPasscode must not be empty");
// 		this.clientPasscode = passcode;
// 		return this;
// 	}

// 	/**
// 	 * Set the login for the shared "system" connection used to send messages to
// 	 * the STOMP broker from within the application, i.e. messages not associated
// 	 * with a specific client session (e.g. REST/HTTP request handling method).
// 	 * <p>By default this is set to "guest".
// 	 */
// 	public StompBrokerRelayRegistration setSystemLogin(string login) {
// 		Assert.hasText(login, "systemLogin must not be empty");
// 		this.systemLogin = login;
// 		return this;
// 	}

// 	/**
// 	 * Set the passcode for the shared "system" connection used to send messages to
// 	 * the STOMP broker from within the application, i.e. messages not associated
// 	 * with a specific client session (e.g. REST/HTTP request handling method).
// 	 * <p>By default this is set to "guest".
// 	 */
// 	public StompBrokerRelayRegistration setSystemPasscode(string passcode) {
// 		Assert.hasText(passcode, "systemPasscode must not be empty");
// 		this.systemPasscode = passcode;
// 		return this;
// 	}

// 	/**
// 	 * Set the interval, in milliseconds, at which the "system" relay session will,
// 	 * in the absence of any other data being sent, send a heartbeat to the STOMP broker.
// 	 * A value of zero will prevent heartbeats from being sent to the broker.
// 	 * <p>The default value is 10000.
// 	 */
// 	public StompBrokerRelayRegistration setSystemHeartbeatSendInterval(long systemHeartbeatSendInterval) {
// 		this.systemHeartbeatSendInterval = systemHeartbeatSendInterval;
// 		return this;
// 	}

// 	/**
// 	 * Set the maximum interval, in milliseconds, at which the "system" relay session
// 	 * expects, in the absence of any other data, to receive a heartbeat from the STOMP
// 	 * broker. A value of zero will configure the relay session to expect not to receive
// 	 * heartbeats from the broker.
// 	 * <p>The default value is 10000.
// 	 */
// 	public StompBrokerRelayRegistration setSystemHeartbeatReceiveInterval(long heartbeatReceiveInterval) {
// 		this.systemHeartbeatReceiveInterval = heartbeatReceiveInterval;
// 		return this;
// 	}

// 	/**
// 	 * Set the value of the "host" header to use in STOMP CONNECT frames. When this
// 	 * property is configured, a "host" header will be added to every STOMP frame sent to
// 	 * the STOMP broker. This may be useful for example in a cloud environment where the
// 	 * actual host to which the TCP connection is established is different from the host
// 	 * providing the cloud-based STOMP service.
// 	 * <p>By default this property is not set.
// 	 */
// 	public StompBrokerRelayRegistration setVirtualHost(string virtualHost) {
// 		this.virtualHost = virtualHost;
// 		return this;
// 	}

// 	/**
// 	 * Configure a TCP client for managing TCP connections to the STOMP broker.
// 	 * <p>By default {@code ReactorNettyTcpClient} is used.
// 	 * <p><strong>Note:</strong> when this property is used, any
// 	 * {@link #setRelayHost(string) host} or {@link #setRelayPort(int) port}
// 	 * specified are effectively ignored.
// 	 * @since 4.3.15
// 	 */
// 	public void setTcpClient(TcpOperations!(byte[]) tcpClient) {
// 		this.tcpClient = tcpClient;
// 	}

// 	/**
// 	 * Configure whether the {@link StompBrokerRelayMessageHandler} should start
// 	 * automatically when the Spring ApplicationContext is refreshed.
// 	 * <p>The default setting is {@code true}.
// 	 */
// 	public StompBrokerRelayRegistration setAutoStartup( autoStartup) {
// 		this.autoStartup = autoStartup;
// 		return this;
// 	}

// 	/**
// 	 * Set a destination to broadcast messages to user destinations that remain
// 	 * unresolved because the user appears not to be connected. In a
// 	 * multi-application server scenario this gives other application servers
// 	 * a chance to try.
// 	 * <p>By default this is not set.
// 	 * @param destination the destination to broadcast unresolved messages to,
// 	 * e.g. "/topic/unresolved-user-destination"
// 	 */
// 	public StompBrokerRelayRegistration setUserDestinationBroadcast(string destination) {
// 		this.userDestinationBroadcast = destination;
// 		return this;
// 	}

	
// 	protected string getUserDestinationBroadcast() {
// 		return this.userDestinationBroadcast;
// 	}

// 	/**
// 	 * Set a destination to broadcast the content of the local user registry to
// 	 * and to listen for such broadcasts from other servers. In a multi-application
// 	 * server scenarios this allows each server's user registry to be aware of
// 	 * users connected to other servers.
// 	 * <p>By default this is not set.
// 	 * @param destination the destination for broadcasting user registry details,
// 	 * e.g. "/topic/simp-user-registry".
// 	 */
// 	public StompBrokerRelayRegistration setUserRegistryBroadcast(string destination) {
// 		this.userRegistryBroadcast = destination;
// 		return this;
// 	}

	
// 	protected string getUserRegistryBroadcast() {
// 		return this.userRegistryBroadcast;
// 	}


// 	protected StompBrokerRelayMessageHandler getMessageHandler(SubscribableChannel brokerChannel) {

// 		StompBrokerRelayMessageHandler handler = new StompBrokerRelayMessageHandler(
// 				getClientInboundChannel(), getClientOutboundChannel(),
// 				brokerChannel, getDestinationPrefixes());

// 		handler.setRelayHost(this.relayHost);
// 		handler.setRelayPort(this.relayPort);

// 		handler.setClientLogin(this.clientLogin);
// 		handler.setClientPasscode(this.clientPasscode);

// 		handler.setSystemLogin(this.systemLogin);
// 		handler.setSystemPasscode(this.systemPasscode);

// 		if (this.systemHeartbeatSendInterval !is null) {
// 			handler.setSystemHeartbeatSendInterval(this.systemHeartbeatSendInterval);
// 		}
// 		if (this.systemHeartbeatReceiveInterval !is null) {
// 			handler.setSystemHeartbeatReceiveInterval(this.systemHeartbeatReceiveInterval);
// 		}
// 		if (this.virtualHost !is null) {
// 			handler.setVirtualHost(this.virtualHost);
// 		}
// 		if (this.tcpClient !is null) {
// 			handler.setTcpClient(this.tcpClient);
// 		}

// 		handler.setAutoStartup(this.autoStartup);

// 		return handler;
// 	}

// }
