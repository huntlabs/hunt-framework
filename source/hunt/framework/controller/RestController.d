
module hunt.framework.controller.RestController;

import hunt.framework.controller.Controller;
import hunt.framework.http.Request;

/**
 * 
 */
class RestController : Controller {

    override Request request() {
        return createRequest(true);
    }

    override protected void handleAuthResponse() {
        // do nothing
    }

}