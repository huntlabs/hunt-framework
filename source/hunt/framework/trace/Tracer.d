module hunt.framework.trace.Tracer;

version(WITH_HUNT_TRACE) :

import hunt.net.util.HttpURI;
import hunt.framework.http.Request;
// import hunt.framework.http.Response;
import hunt.trace;
import hunt.logging.ConsoleLogger;

import std.conv;
import std.format;

__gshared isTraceEnabled = true;

// void newFrameworkTrace(Request req) {
//     version (WITH_HUNT_TRACE) {
//         if (!tracing())
//             return;
//         version (WITH) auto tracer = new Tracer(req.getMCA(),
//                 req.headerExists("b3") ? req.header("b3") : "");
//         tracer.root.addTag(HTTP_HOST, req.host);
//         tracer.root.addTag(HTTP_URL, req.url);
//         tracer.root.addTag(HTTP_PATH, req.path);
//         tracer.root.addTag(HTTP_METHOD, req.methodAsString);
//         tracer.root.addTag(HTTP_REQUEST_SIZE, to!string(req.size));
//         tracer.root.start();
//         setTracer(tracer);
//     }
// }

// void finishFrameworkTrace(string error) {
//     version (WITH_HUNT_TRACE) {
//         auto tracer = getTracer();
//         if (tracer is null)
//             return;
//         tracer.root.addTag(SPAN_ERROR, error);
//         finishFrameworkUpload(tracer);
//     }
// }

// void finishFrameworkTrace(Response response) {
//     version (WITH_HUNT_TRACE) {
//         auto tracer = getTracer();
//         if (tracer is null)
//             return;

//         tracer.root.addTag(HTTP_STATUS_CODE, to!string(response.status));
//         tracer.root.addTag(HTTP_RESPONSE_SIZE, to!string(response.size));
//         finishFrameworkUpload(tracer);
//     }
// }

// private void finishFrameworkUpload(Tracer tracer) {
//     version (WITH_HUNT_TRACE) {
//         tracer.root.finish();

//         uploadFromIMF(tracer.root ~ tracer.children);

//         version (HUNT_DEBUG)
//             logInfo(" mca: ", tracer.root.name, " duration: ",
//                     tracer.root.duration / 1000, " traceId: ", tracer.root.traceId);
//     }
// }


// void endTraceSpan(Request request, int status, string message = null) {

//     if(!isTraceEnabled) return;

//     Tracer tracer = request.tracer;
//     if(tracer is null) {
//         version(HTTP_DEBUG) warning("no tracer defined");
//         return;
//     }

//     HttpURI uri = request.getURI();
//     string[string] tags;
//     tags[HTTP_HOST] = uri.getHost();
//     tags[HTTP_URL] = uri.getPathQuery();
//     tags[HTTP_PATH] = uri.getPath();
//     tags[HTTP_REQUEST_SIZE] = request.getContentLength().to!string();
//     tags[HTTP_METHOD] = request.methodAsString();

//     Span span = tracer.root;
//     if(span !is null) {
//         tags[HTTP_STATUS_CODE] = to!string(status);
//         traceSpanAfter(span, tags, message);
//         httpSender().sendSpans(span);
//     } else {
//         warning("No span sent");
//     }
// }