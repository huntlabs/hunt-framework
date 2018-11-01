module hunt.framework.websocket.exception;

import hunt.http.codec.websocket.model.CloseStatus;
import hunt.lang.exception;

class SessionLimitExceededException : RuntimeException {
    
	private CloseStatus status;

	this(string message, CloseStatus status) {
		super(message);
		this.status = (status !is null ? status : CloseStatus.NO_STATUS_CODE);
	}


	CloseStatus getStatus() {
		return this.status;
	}

}
