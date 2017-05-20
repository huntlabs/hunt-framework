/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.application.middleware;

import hunt.http.request;
import hunt.http.response;


interface IMiddleware
{
    ///get the middleware name
    string name();
    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null);
}
