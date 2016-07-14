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
module hunt.router.middleware;

import std.concurrency;

import hunt.routing.middleware;
import hunt.http.request;
import hunt.http.response;

alias RouterMiddleWare = IMiddleWare!(Request, Response);
alias RouterPipeline = PipelineImpl!(Request, Response);
alias RouterPipelineFactory = IPipelineFactory!(Request, Response);
alias RouterPipelineContext = RouterPipeline.Context;

interface Widget
{
	bool handle(Request req, Response res);
}

abstract shared class IWidgetFactory
{
	Widget[] getWidgets();
}
