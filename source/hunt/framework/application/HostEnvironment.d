module hunt.framework.application.HostEnvironment;

import hunt.framework.Init;

import std.process;
import std.range;

// 
enum ENV_APP_NAME = "APP_NAME";
enum ENV_APP_VERSION = "APP_VERSION";
enum ENV_APP_ENV = "APP_ENV";
enum ENV_APP_LANG = "APP_LANG";
enum ENV_APP_KEY = "APP_KEY";
enum ENV_APP_BASE_PATH = "APP_BASE_PATH";
enum ENV_CONFIG_BASE_PATH = "CONFIG_BASE_PATH";


/**
 * 
 */
class HostEnvironment {
    string _name = DEFAULT_RUNTIME_ENVIRONMENT;
    string _configPath = DEFAULT_CONFIG_LACATION;

    this() {
        string value = environment.get("HUNT_ENV", "");
        if(value.empty) {
            value = environment.get(ENV_APP_ENV, "");
        }

        if(!value.empty) {
            _name = value;
        }
    }

    string name() {
        return _name;
    }

    HostEnvironment name(string value) {
        _name = value;
        return this;
    }

    string configPath() {
        return _configPath;
    }

    HostEnvironment configPath(string value) {
        if (value[$ - 1] == '/')
            _configPath = value;
        else
            _configPath = value ~ "/";        
        return this;
    }

    bool isProduction() {
        return _name == "production";
    }

    bool isDevelopment() {
        return _name == "development" || _name == DEFAULT_RUNTIME_ENVIRONMENT;
    }

    bool isTest() {
        return _name == "test";
    }

    bool isStaging() {
        return _name == "staging";
    }

    bool isEnvironment(string name) {
        return _name == name;
    }    

}