module hunt.framework.websocket.Exceptions;

import hunt.http.codec.websocket.model.CloseStatus;
import hunt.Exceptions;

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
