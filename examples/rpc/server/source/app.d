import std.stdio;
import std.functional;

import collie.socket.eventloopgroup;
import hunt.console.application;
import hunt.console.messagecoder;
import message;


alias RPCContext = ServerApplication!(false).Contex;

enum MSGType :ushort
{
    BEAT,
    DATA
}

void main()
{
	writeln("Edit source/app.d to start your project.");
	ServerApplication!false  server = new ServerApplication!false ();
	server.addRouter(MSGType.BEAT,toDelegate(&handleBeat));
	server.addRouter(MSGType.DATA,toDelegate(&handleData),new MiddlewareFactroy());
	server.heartbeatTimeOut(120).bind(9002);
	server.group(new EventLoopGroup());
	server.run();
}


class MiddlewareFactroy : ServerApplication!(false).RouterPipelineFactory
{
    override ServerApplication!(false).RouterPipeline newPipeline()
    {
        auto pipe  =  new ServerApplication!(false).RouterPipeline;
        pipe.addHandler(new Middleware());
        return pipe;
    }
}

class Middleware : ServerApplication!(false).MiddleWare
{
    override void handle(Context ctx, Message req, RPCContext res)
    {
        TypeMessage msg = cast(TypeMessage)req;
        if(msg is null) return;
        MyMessage mmsg = MyMessage.decodeMeassage!false(msg.data);
        if(mmsg)
            ctx.next(mmsg,res);
        else
            writeln("data erro!");
    }
}


void handleData(Message msg , RPCContext ctx)
{
    MyMessage mmsg = cast(MyMessage)msg;
    if(mmsg is null)
    {
        writeln("data erro close");
        ctx.close();
    }
    switch (mmsg.commod)
    {
        case 0:
            mmsg.value = mmsg.fvalue + mmsg.svalue;
            break;
        case 1:
            mmsg.value = mmsg.fvalue - mmsg.svalue;
            break;
        case 2:
            mmsg.value = mmsg.fvalue * mmsg.svalue;
            break;
        case 3:
            mmsg.value = mmsg.fvalue / mmsg.svalue;
            break;
        default:
            mmsg.value = mmsg.fvalue;
            break;
    }
    ctx.write(mmsg);
}

void handleBeat(Message msg , RPCContext ctx)
{
    TypeMessage mmsg = cast(TypeMessage)msg;
    writeln("Heatbeat: data : " , cast(string)mmsg.data);
    ctx.write(MSGType.BEAT, cast(ubyte[])"server");
}

