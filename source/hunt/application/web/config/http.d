
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
module hunt.application.web.config.http;

import std.conv;
import std.socket;
import std.parallelism;

import collie.bootstrap.serversslconfig;

import hunt.text.conf;

abstract class WebSocketFactory
{
    import collie.codec.http;
    WebSocket newWebSocket(const HTTPHeader header);
}


class HTTPConfig
{
    this(string file)
    {
        _ini = new Conf(file);
    }
    
    Address bindAddress()
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
    
    uint threadSize()
    {
        return _ini.get!uint("server.threadsize",totalCPUs);
    }
    
    
    WebSocketFactory webSocketFactory()
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
    
    uint keepAliveTimeOut()
    {
        return _ini.get!uint("server.timeout",30);
    }
    
    uint httpMaxBodySize(){return _ini.get!uint("http.maxbody",8 * 1024 * 1024);}
    
    uint httpMaxHeaderSize(){return _ini.get!uint("http.maxheader",4 * 1024);}
    
    uint httpHeaderStectionSize(){return _ini.get!uint("http.headersection",2048);}
    
    uint httpRequestBodyStectionSize(){return _ini.get!uint("http.requestsection", 16 * 1024);}
    
    uint httpResponseBodyStectionSize(){return _ini.get!uint("http.responsesection", 16 * 1024);}
    
    ServerSSLConfig sslConfig()
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
        
        return ssl;
    }
      
private:
    Conf _ini;
}