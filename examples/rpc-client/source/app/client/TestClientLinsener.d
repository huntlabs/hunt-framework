


module service.TestClientLinsener;

import kissrpc.RpcClientListener;
import kiss.aio.AsynchronousChannelSelector;
import kissrpc.RpcSocketBaseInterface;
import kissrpc.Logs;

import kissrpc.generated.TestRpcMessage;
import kissrpc.generated.TestRpcService;
import kissrpc.Unit;

import std.conv;
import std.stdio;
import core.time;
import std.datetime;
import std.conv;



static int testNum = 1000000;
static int atestNum = 1000000;

class TestClientLinsener : RpcClientListener {
    this (string ip, ushort port, AsynchronousChannelSelector sel) 
    {
        super(ip, port, sel);
    }
    override void connectd(RpcSocketBaseInterface socket)
	{
        writefln("connect to server, %s:%s", socket.getIp, socket.getPort);
		RpcTestService service = new RpcTestService(_rpClient);

		auto startTime  = Clock.currStdTime().stdTimeToUnixTime!(long)();



		writefln("start sync test.......................");
		for(int i= 1; i <= testNum; ++i)
		{
			UserInfo user;
			user.name = "helloworld";
			user.i = i;

			try{
				auto s = service.getName(user);
				
				if(s.i % 50000 == 0)
				{
					writefln("ret:%s, request:%s, time:%s", s, i, Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime);
				}
			}catch(Exception e)
			{
				writeln(e.msg);
			}


		}

		auto time = Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime;

		writefln("sync test, total request:%s, time:%s, QPS:%s\n\n", testNum, time, testNum/time);




		// startTime  = Clock.currStdTime().stdTimeToUnixTime!(long)();
	
		// writefln("start async test.......................");

		// for(int i= 1; i <= atestNum; ++i)
		// {
		// 	UserInfo user;
		// 	user.name = "jasonaslex";
		// 	user.i = i;
				
		// 	try{
		// 		service.getName(user, delegate(UserInfo s){
						
		// 				if(s.i%50000 == 0)
		// 				{
		// 					writefln("ret:%s, request:%s, time:%s", s, s.i, Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime);
		// 				}
						
		// 				if(s.i == atestNum)
		// 				{
		// 					time = Clock.currStdTime().stdTimeToUnixTime!(long)() - startTime;
		// 					writefln("async test, total request:%s, time:%s, QPS:%s", s.i, time, atestNum/time);
		// 				}

		// 			});
		// 	}catch(Exception e)
		// 	{
		// 		writeln(e.msg);

		// 	}


		// }
	}
}