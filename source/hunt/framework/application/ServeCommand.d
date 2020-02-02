module hunt.framework.application.ServeCommand;

import hunt.framework.Init;

import hunt.console;
import hunt.logging.ConsoleLogger;

import core.stdc.stdlib : exit;
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
    enum string ConfigOption = "config";


    this() {
        super("serve");
    }

    override protected void configure() {
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

        addOption(ConfigOption, "c", InputOption.VALUE_OPTIONAL,
            "Set the config file",
            "config/application.conf");

        // addArgument(ConfigOption, InputArgument.OPTIONAL, 
        //     "Set the config file (Default: config/application.conf)");

    }

    override protected int execute(Input input, Output output) {
        string hostname = input.getOption(HostNameOption);
        string port = input.getOption(PortOption);
        string bind = input.getOption(BindOption);
        string config = input.getOption(ConfigOption);

        if (!bind.empty && bind != "0.0.0.0:8080") {
            // 0.0.0.0:8080, 0.0.0.0, parse hostname and port
            string[] parts = bind.split(":");
            if(parts.length<2) {
                output.writeln("Wrong format for the bind argument.");
                exit(1);
            }

            hostname = parts[0];
            port = parts[1];
        }

        output.writeln(format("launching server, %s:%s", hostname, port));
        output.writeln(format("using config, %s", hostname, port));

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
