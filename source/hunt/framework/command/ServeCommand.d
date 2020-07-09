module hunt.framework.command.ServeCommand;

import hunt.framework.Init;

import hunt.console;
import hunt.logging.ConsoleLogger;

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
            "Set the hostname the server will run on.",
            "0.0.0.0");

        addOption(PortOption, "p", InputOption.VALUE_OPTIONAL,
            "Set the port the server will run on.",
            "8080");

        addOption(BindOption, "b", InputOption.VALUE_OPTIONAL,
            "Convenience for setting hostname and port together.",
            "0.0.0.0:8080");

        addOption(EnvironmentOption, "e", InputOption.VALUE_OPTIONAL,
            "Set the runtime environment.", DEFAULT_RUNTIME_ENVIRONMENT);

        addOption(ConfigPathOption, "cp", InputOption.VALUE_OPTIONAL,
            "Set the location for config files",
            DEFAULT_CONFIG_LACATION);

        // addOption(ConfigFileOption, "cf", InputOption.VALUE_OPTIONAL,
        //     "Set the name of the main config file",
        //     DEFAULT_CONFIG_FILE);

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
    string host = "0.0.0.0";
    ushort port = 8080;
    string configPath = DEFAULT_CONFIG_LACATION;
    // string configFile = DEFAULT_CONFIG_FILE;
    string environment = DEFAULT_RUNTIME_ENVIRONMENT;
}

alias CommandInputHandler = void delegate(ServeSignature signature);