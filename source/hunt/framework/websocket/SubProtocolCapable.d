module hunt.framework.websocket.SubProtocolCapable;

/**
 * An interface for WebSocket handlers that support sub-protocols as defined in RFC 6455.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 * @see WebSocketHandler
 * @see <a href="http://tools.ietf.org/html/rfc6455#section-1.9">RFC-6455 section 1.9</a>
 */
interface SubProtocolCapable {

	/**
	 * Return the list of supported sub-protocols.
	 */
	string[] getSubProtocols();
}
