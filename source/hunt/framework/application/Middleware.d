/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.application.Middleware;

import hunt.framework.http.Request;
import hunt.framework.http.Response;


interface Middleware
{
    ///get the middleware name
    string name();
    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null);
}
