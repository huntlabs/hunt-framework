module hunt.framework.provider.UserServiceProvider;


import hunt.framework.provider.ServiceProvider;
import hunt.framework.auth.SimpleUserService;
import hunt.framework.auth.UserService;

import hunt.logging;
import poodinis;


/**
 * 
 */
class UserServiceProvider : ServiceProvider {
    
    override void register() {
        container.register!(UserService, SimpleUserService).singleInstance();
    }
}