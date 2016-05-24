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
module hunt.console.middleware;


import hunt.web.router.middleware;
import hunt.console.messagecoder;
import hunt.console.context;

alias MiddleWare = IMiddleWare!(Message, ConsoleContext);
alias RouterPipeline = PipelineImpl!(Message, ConsoleContext);
alias RouterPipelineFactory = IPipelineFactory!(Message, ConsoleContext);