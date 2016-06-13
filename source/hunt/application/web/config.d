module hunt.application.web.config;

import std.socket;
import std.parallelism;

import collie.bootstrap.serversslconfig;

import hunt.routing.configbase;

abstract class WebSocketFactory
{
    import collie.codec.http;
    WebSocket newWebSocket(const HTTPHeader header);
}

class WebConfig
{
    Address bindAddress(){return new InternetAddress(8080);}
    
    uint threadSize(){return totalCPUs;}
    
    WebSocketFactory webSocketFactory(){return null;}
    
    uint keepAliveTimeOut(){return 30;}
    
    uint httpMaxBodySize(){return 8 * 1024 * 1024;}
    
    uint httpMaxHeaderSize(){return 4 * 1024;}
    
    uint httpHeaderStectionSize(){return 2048;}
    
    uint httpRequestBodyStectionSize(){return 16 * 1024;}
    
    uint httpResponseBodyStectionSize(){return 16 * 1024;}
    
    ServerSSLConfig sslConfig(){return null;}
    
    RouterConfigBase routerConfig()
    {
        import hunt.web.router.configsignalmodule;
        return new ConfigSignalModule("config/router.conf");
    }
}

import hunt.text.ini;
import std.conv;

class IniWebConfig : WebConfig
{
    this(string file)
    {
        _ini = new Ini(file);
    }
    
    override Address bindAddress()
    {
        auto value = _ini.value("server","port");
        if(value.length == 0) 
            throw new Exception("The Port Config can not be empty!");
        ushort port = to!ushort(value);
        value = _ini.value("server","host");
        if(value.length == 0)
        {
            return new InternetAddress(port);
        }
        else
        {
            auto ip = value;
            value = _ini.value("server","isipv6");
            if(value.length == 0)
            {
                return new InternetAddress(ip,port);
            }
            
            bool ip6 = to!bool(value);
            if(ip6)
                return new Internet6Address(ip,port);
            else
                return new InternetAddress(ip,port);
        }
    }
    
    override uint threadSize()
    {
        auto value = _ini.value("server","threadsize");
        if(value.length == 0)
            return super.threadSize();
        return to!uint(value);
    }
    
    
private:
    Ini _ini;
}