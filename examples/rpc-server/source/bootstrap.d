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

import std.stdio;
import std.functional;
import std.experimental.logger;

import hunt;

import kissrpc.RpcServerListener;
import kissrpc.generated.TestRpcService;

void main()
{

    auto app = Application.getInstance();
    app.startRpcService!(RpcServerListener,RpcTestService)();
    app.run();

}

