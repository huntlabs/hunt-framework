module hunt.framework.service.ServiceProvider;

import poodinis;

abstract class ServiceProvider {

    package DependencyContainer _container;

    DependencyContainer container() {
        return _container;
    }

    /**
     * Register any application services.
     *
     * @return void
     */
    void register();


    /**
     * Bootstrap the application events.
     *
     * @return void
     */
    void boot() {}
}