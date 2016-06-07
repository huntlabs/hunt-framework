import std.stdio;
import std.functional;

import collie.socket.eventloopgroup;
import hunt.server.stream;
import hunt.stream.messagecoder;
import message;


alias RPCContext = StreamServer!(false).Contex;


void main()
{
	writeln("Edit source/app.d to start your project.");
	StreamServer!false  server = new StreamServer!false ();
	server.addRouter(MSGType.BEAT.stringof,toDelegate(&handleBeat));
	server.addRouter(MSGType.DATA.stringof,toDelegate(&handleData),new MiddlewareFactroy());
	server.heartbeatTimeOut(120).bind(8094);
	server.setMessageDcoder(new MyDecode());
	server.group(new EventLoopGroup());
	server.run();
}


class MiddlewareFactroy : StreamServer!(false).RouterPipelineFactory
{
    override StreamServer!(false).RouterPipeline newPipeline()
    {
        auto pipe  =  new StreamServer!(false).RouterPipeline;
        pipe.addHandler(new Middleware());
        return pipe;
    }
}

class Middleware : StreamServer!(false).MiddleWare
{
    override void handle(Context ctx, RPCContext res,Message req)
    {
        writeln("\t\tMiddleware : StreamServer!(false).MiddleWare");
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

