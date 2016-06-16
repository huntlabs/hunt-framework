import std.stdio;
import std.functional;
import std.datetime;
import std.variant;

import collie.socket.eventloopgroup;
import hunt.application.stream;
import hunt.stream.messagecoder;
import message;


alias RPCContext = StreamApplication!(false).Contex;

void main()
{
	writeln("Edit source/app.d to start your project.");
	StreamApplication!false  server = new StreamApplication!false ();
	server.addRouter(MSGType.BEAT.stringof,toDelegate(&handleBeat));
	server.addRouter(MSGType.DATA.stringof,toDelegate(&handleData),new MiddlewareFactroy());
	server.addRouter("TimeOut",delegate(RPCContext ctx,Message){
            writeln("Time out !@!!");
            ctx.close();
	});
	server.addRouter("TransportActive",delegate(RPCContext ctx,Message){
            writeln("new connect start.");
            Variant tmp = Clock.currTime();
            ctx.setData(tmp);
        });
        server.addRouter("TransportInActive",delegate(RPCContext ctx,Message){
            auto date = ctx.data.get!SysTime();
            writeln("connect closed!, the connect time is : ",date);
        });
	server.heartbeatTimeOut(120).bind(8094);
	server.setMessageDcoder(new MyDecode());
	server.group(new EventLoopGroup());
	server.run();
}


class MiddlewareFactroy : StreamApplication!(false).RouterPipelineFactory
{
    override StreamApplication!(false).RouterPipeline newPipeline()
    {
        auto pipe  =  new StreamApplication!(false).RouterPipeline;
        pipe.addHandler(new Middleware());
        return pipe;
    }
}

class Middleware : StreamApplication!(false).MiddleWare
{
    override void handle(Context ctx, RPCContext res,Message req)
    {
        writeln("\t\tMiddleware : StreamApplication!(false).MiddleWare");
        ctx.next(res,req);
    }
}

void handleData(RPCContext ctx,Message msg )
{
    DataMessage mmsg = cast(DataMessage)msg;
    if(mmsg is null)
    {
        writeln("data erro close");
        ctx.close();
    }
    write(" \t\tMyMessage IS : ", mmsg.fvalue);
    switch (mmsg.commod)
    {
        case 0:
            mmsg.value = mmsg.fvalue + mmsg.svalue;
            write(" + ");
            break;
        case 1:
            mmsg.value = mmsg.fvalue - mmsg.svalue;
            write(" - ");
            break;
        case 2:
            mmsg.value = mmsg.fvalue * mmsg.svalue;
            write(" * ");
            break;
        case 3:
            mmsg.value = mmsg.fvalue / mmsg.svalue;
            write(" / ");
            break;
        default:
            mmsg.value = mmsg.fvalue;
            write(" ? ");
            break;
    }
    writeln(mmsg.svalue, "  =  ", mmsg.value);
    ctx.write(mmsg);
}

void handleBeat(RPCContext ctx,Message msg)
{
    BeatMessage mmsg = cast(BeatMessage)msg;
    writeln("\nHeatbeat: data : " , cast(string)mmsg.data);
    mmsg.data = cast(ubyte[])"server";
    ctx.write(mmsg);
}

