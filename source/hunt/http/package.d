module hunt.http;

public import hunt.router;
public import hunt.http.request;
public import hunt.http.response;
public import hunt.http.cookie;
public import hunt.http.controller;
public import hunt.http.session;
public import hunt.http.sessionstorage;
public import hunt.http.webfrom;

alias HTTPRouter = Router!(Request, Response);
alias RouterPipeline = PipelineImpl!(Request, Response);
alias RouterPipelineFactory = IPipelineFactory!(Request, Response);
alias MiddleWare = IMiddleWare!(Request, Response);
alias DOHandler = void delegate(Request, Response);