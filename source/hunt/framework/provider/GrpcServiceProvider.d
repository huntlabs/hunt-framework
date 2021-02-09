module hunt.framework.provider.GrpcServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config;
import hunt.http.HttpVersion;
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
                import hunt.http.server.HttpServerOptions;

                auto httpServerOptions = new HttpServerOptions();
                httpServerOptions.setSecureConnectionEnabled(false);
                httpServerOptions.setFlowControlStrategy("simple");
                httpServerOptions.getTcpConfiguration().workerThreadSize = serverConf.workerThreads;
                //httpServerOptions.getTcpConfiguration().setTimeout(60 * 1000);
                httpServerOptions.setProtocol(HttpVersion.HTTP_2.asString());

                GrpcServer server = new GrpcServer(httpServerOptions);
                server.listen(serverConf.host, serverConf.port);
                infof("gRPC server started at %s:%d.", serverConf.host, serverConf.port);
                return server;
            } else {
                // version(HUNT_DEBUG) warning("The GrpcService is disabled.");
                throw new Exception("The GrpcService is disabled.");
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
