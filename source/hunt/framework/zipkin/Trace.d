module hunt.framework.zipkin.Trace;

import hunt.framework.http.Request;
import hunt.framework.http.Response;

import zipkin;
import hunt.logging;

import std.conv;


void newFrameworkTrace(Request req)
{
    auto trace = new Trace(req.getMCA());
    trace.root.addTag(HTTP_HOST , req.host);
    trace.root.addTag(HTTP_URL , req.url);
    trace.root.addTag(HTTP_PATH , req.path);
    trace.root.addTag(HTTP_METHOD , req.method);
    trace.root.addTag(HTTP_REQUEST_SIZE ,  to!string(req.size));
    trace.root.start();
    setTrace(trace);
}

void finishFrameworkTrace(string error)
{
    auto trace = getTrace();
    trace.root.addTag(SPAN_ERROR , error);
    finishFrameworkUpload(trace);
}

void finishFrameworkTrace(Response response)
{
    auto trace = getTrace();
    trace.root.addTag(HTTP_STATUS_CODE , to!string(response.status));
    trace.root.addTag(HTTP_RESPONSE_SIZE , to!string(response.size));
    finishFrameworkUpload(trace);  
}

private void finishFrameworkUpload(Trace trace)
{
    trace.root.finish();

    if(trace.upload)
        uploadFromIMF(trace.root ~ trace.children);

    version(HUNT_DEBUG) logInfo(" mca: " , trace.root.name , " duration: " , 
        trace.root.duration / 1000 , " traceId: " , trace.root.traceId );
}



