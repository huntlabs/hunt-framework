module hunt.framework.provider.GrpcServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config;
import hunt.logging.ConsoleLogger;
import grpc;

import poodinis;

import std.algorithm;
import std.array;
import std.format;
import std.string;


/**
 * 
 */
class GrpcServiceProvider : ServiceProvider {

    private bool isGrpcServerEnabled = false;

    override void register() {
        container().register!(GrpcServer)(() {
            ApplicationConfig appConfig = container().resolve!ApplicationConfig();
            GrpcServerConf serverConf = appConfig.grpc.server;
            isGrpcServerEnabled = serverConf.enabled;
            if(isGrpcServerEnabled) {
                GrpcServer server = new GrpcServer();
                server.listen(serverConf.host, serverConf.port);
                return server;
            } else {
                version(HUNT_DEBUG) warning("The GrpcService is disabled.");
                return null;
            }

        }).singleInstance();

        container().register!(GrpcService)(() {
            ApplicationConfig appConfig = container().resolve!ApplicationConfig();
            return new GrpcService(appConfig.grpc.clientChannels);

        }).singleInstance();        

    }

    override void boot() {
        if(isGrpcServerEnabled) {
            GrpcServer grpcServer = container().resolve!GrpcServer();
            grpcServer.start();

            warning("grpc server started.");
        }
    }
}


/**
 * 
 */
class GrpcService {
    
    private GrpcClientConf[string] _clientOptions;

    this(GrpcClientConf[] clientOptions) {
        foreach(ref GrpcClientConf conf; clientOptions) {
            _clientOptions[conf.name] = conf;
        }
    }


    GrpcServer server() {
        return serviceContainer().resolve!GrpcServer();
    }

    Channel getChannel(string name) {
        GrpcClientConf* itemPtr = name in _clientOptions;
        if(itemPtr is null) {
            throw new Exception(format("No options found for %s", name));
        }
        return new Channel(itemPtr.host, itemPtr.port);        
    }
}
