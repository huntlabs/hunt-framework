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
        import hunt.web.router.config;
        return new RouterConfig("config/router.conf");
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
            bool ip6 = _ini.get!bool("server.isipv6", false);
            if(ip6)
                return new Internet6Address(value,port);
            else
                return new InternetAddress(value,port);
        }
    }
    
    override uint threadSize()
    {
        return _ini.get!uint("server.threadsize",totalCPUs);
    }
    
    
    override WebSocketFactory webSocketFactory()
    {
        auto value = _ini.get("server.websocket");
        WebSocketFactory socket = null;
        if(value.length)
        {
            auto obj = Object.factory(value);
            if(obj) socket = cast(WebSocketFactory)obj;
        }
        return socket;
    }
    
    override uint keepAliveTimeOut()
    {
        return _ini.get!uint("server.timeout",30);
    }
    
    override uint httpMaxBodySize(){return _ini.get!uint("http.maxbody",8 * 1024 * 1024);}
    
    override uint httpMaxHeaderSize(){return _ini.get!uint("http.maxheader",4 * 1024);}
    
    override uint httpHeaderStectionSize(){return _ini.get!uint("http.headersection",2048);}
    
    override uint httpRequestBodyStectionSize(){return _ini.get!uint("http.requestsection", 16 * 1024);}
    
    override uint httpResponseBodyStectionSize(){return _ini.get!uint("http.responsesection", 16 * 1024);}
    
    override ServerSSLConfig sslConfig()
    {
        import std.string;
        auto mode = _ini.get("server.ssl.mode");
        if(mode.length == 0) return null;
        SSLMode md;
        mode = toUpper(mode);
        switch(mode)
        {
            case "SSLV2V3" :
                md = SSLMode.SSLv2v3;
                break;
            case "TLSV1" :
                md = SSLMode.TLSv1;
                break;
            case "TLSV1_1" :
                md = SSLMode.TLSv1_1;
                break;
            case "TLSV1_2" :
                md = SSLMode.TLSv1_2;
                break;
            default:
                throw new Exception("ssl Mode is not support!");
        }
        ServerSSLConfig ssl = new ServerSSLConfig(md);
        ssl.certificateFile(_ini.get("server.ssl.certificate"));
        ssl.privateKeyFile(_ini.get("server.ssl.privatekey"));
     //   ssl.cipherList(_ini.get("server.ssl.cipher"));
        
        return ssl;
    }
    
    override RouterConfigBase routerConfig()
    {
        auto value = _ini.get("router.configpath");
        import hunt.web.router.config;
        return new RouterConfig(value);
    }
    
private:
    Conf _ini;
}