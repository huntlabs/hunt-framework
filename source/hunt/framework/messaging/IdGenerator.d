module hunt.framework.messaging.IdGenerator;

import std.uuid;

/**
 * Contract for generating universally unique identifiers {@link UUID (UUIDs)}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
interface IdGenerator {

	/**
	 * Generate a new identifier.
	 * @return the generated identifier
	 */
	UUID generateId();
}
