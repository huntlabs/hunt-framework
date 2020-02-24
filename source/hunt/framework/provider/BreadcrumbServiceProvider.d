module hunt.framework.provider.BreadcrumbServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.application.BreadcrumbsManager;
import hunt.framework.application.Breadcrumbs;

import hunt.logging.ConsoleLogger;
import poodinis;

/**
 * 
 */
class BreadcrumbServiceProvider : ServiceProvider {

    BreadcrumbsManager breadcrumbs() {
        return container.resolve!BreadcrumbsManager();
    }

    override void register() {
        container.register!(BreadcrumbsManager)().singleInstance();
    }
}