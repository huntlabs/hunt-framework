module hunt.framework.provider.TranslationServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.application.ApplicationConfig;

import hunt.framework.i18n.I18n;
import hunt.framework.Init;

import poodinis;

/**
 * 
 */
class TranslationServiceProvider : ServiceProvider {

    override void register() {
        container.register!(I18n)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();
            I18n i18n = new I18n();

            i18n.defaultLocale = config.application.defaultLanguage;
            i18n.loadLangResources(config.application.langLocation);
            return i18n;
        }).singleInstance();
    }
}