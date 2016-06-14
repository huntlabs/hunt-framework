/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.web.application.config;

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

import hunt.text.conf;
import std.conv;

class IniWebConfig : WebConfig
{
    this(string file)
    {
        _ini = new Conf(file);
    }
    
    override Address bindAddress()
    {
        auto value = _ini.get("server.port");
        if(value.length == 0) 
            throw new Exception("The Port Config can not be empty!");
        ushort port = to!ushort(value);
        value = _ini.get("server.host");
        if(value.length == 0)
        {
            return new InternetAddress(port);
        }
        else
        {
            auto ip = value;
            value = _ini.get("server.isipv6");
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
        auto value = _ini.get("server.threadsize");
        if(value.length == 0)
            return super.threadSize();
        return to!uint(value);
    }
    
    
private:
    Conf _ini;
}