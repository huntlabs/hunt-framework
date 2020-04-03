module hunt.framework.provider.BreadcrumbServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.breadcrumb.BreadcrumbsManager;
import hunt.framework.breadcrumb.Breadcrumbs;

import poodinis;

/**
 * 
 */
class BreadcrumbServiceProvider : ServiceProvider {

    BreadcrumbsManager breadcrumbs() {
        return container.resolve!BreadcrumbsManager();
    }

    override void register() {
        container.register!(BreadcrumbsManager).singleInstance();
    }
}
