module hunt.framework.provider.TranslationServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.framework.i18n.I18n;
import hunt.framework.Init;
import hunt.logging.ConsoleLogger;

import poodinis;
import std.path;

/**
 * 
 */
class TranslationServiceProvider : ServiceProvider {

    override void register() {
        container.register!I18n.initializedBy({
            ApplicationConfig config = container.resolve!ApplicationConfig();
            string langLocation = config.application.langLocation;
            langLocation = buildPath(DEFAULT_RESOURCE_PATH, langLocation); 

            I18n i18n = new I18n();
            i18n.defaultLocale = config.application.defaultLanguage;
            i18n.loadLangResources(langLocation);
            return i18n;
        }).singleInstance();
    }
}