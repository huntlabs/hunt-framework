module hunt.framework.command.ServeCommand;

import hunt.framework.Init;

import hunt.console;
import hunt.logging.Logger;

import core.stdc.stdlib : exit;

import std.conv;
import std.format;
import std.range;
import std.string;

/**
 * 
 */
class ServeCommand : Command {
    enum string HostNameOption = "hostname";
    enum string PortOption = "port";
    enum string BindOption = "bind";
    enum string ConfigPathOption = "config-path";
    // enum string ConfigFileOption = "config-file";
    enum string EnvironmentOption = "env"; // development, production, staging

    private CommandInputHandler _inputHandler;


    this() {
        super("serve");
    }

    void onInput(CommandInputHandler handler) {
        _inputHandler = handler;
    }

    override protected void configure() {
        // https://symfony.com/doc/current/components/console/console_arguments.html
        // https://symfony.com/doc/current/console/input.html
        setDescription("Begins serving the app over HTTP.");

        addOption(HostNameOption, "H", InputOption.VALUE_OPTIONAL,
            "Set the hostname the server will run on. (Using the setting in config file by default)"); 
            // DEFAULT_HOST
            // (Using the setting in config file by default)

        addOption(PortOption, "p", InputOption.VALUE_OPTIONAL,
            "Set the port the server will run on. (Using the setting in config file by default)"); 
            // (Using the setting in config file.)

        addOption(BindOption, "b", InputOption.VALUE_OPTIONAL,
            "Convenience for setting hostname and port together."); 
            // (Using the setting in config file.)

        addOption(EnvironmentOption, "e", InputOption.VALUE_OPTIONAL,
            "Set the runtime environment."); 
            // DEFAULT_RUNTIME_ENVIRONMENT

        addOption(ConfigPathOption, "c", InputOption.VALUE_OPTIONAL,
            "Set the location for config files",
            DEFAULT_CONFIG_LACATION);
    }

    override protected int execute(Input input, Output output) {
        string hostname = input.getOption(HostNameOption);
        string port = input.getOption(PortOption);
        string bind = input.getOption(BindOption);
        string configPath = input.getOption(ConfigPathOption);
        // string configFile = input.getOption(ConfigFileOption);
        string envionment = input.getOption(EnvironmentOption);

        if (!bind.empty && bind != "0.0.0.0:8080") {
            // 0.0.0.0:8080, 0.0.0.0, parse hostname and port
            string[] parts = bind.split(":");
            if(parts.length<2) {
                output.writeln("Wrong format for the bind option.");
                exit(1);
            }

            hostname = parts[0];
            port = parts[1];
        }

        if(port.empty()) port = "0";

        if(_inputHandler !is null) {
            ServeSignature signature = ServeSignature(hostname, port.to!ushort, 
                configPath, envionment); // configFile, 
                
            _inputHandler(signature);
        }

        return 0;
    }

    override protected void interact(Input input, Output output) {
        // if (input.getArgument("name") is null) {
        //     string name = (cast(QuestionHelper)(getHelper("question"))).ask(input,
        //             output, new Question("What is your name?"));
        //     input.setArgument("name", name);
        // }
    }
}

/**
 * 
 */
struct ServeSignature {
    string host = DEFAULT_HOST;
    ushort port = DEFAULT_PORT;
    string configPath = DEFAULT_CONFIG_LACATION;
    // string configFile = DEFAULT_CONFIG_FILE;
    string environment; // = DEFAULT_RUNTIME_ENVIRONMENT;
}

alias CommandInputHandler = void delegate(ServeSignature signature);