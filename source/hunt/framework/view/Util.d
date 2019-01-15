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

module hunt.framework.view.Util;

import std.stdio;
import std.regex;

class Util
{
    static string[string] parseFormData(string idstring)
	{
        import std.string;
		string[string] params;
		auto idstr = strip(idstring);
        string[] param_section;
		param_section = split(idstr, '&');
        foreach(section; param_section) {
            auto param = split(section,"=");
            if(param.length == 2)
            {
                params[param[0]] = param[1];
            }
        }
		
		return params;
	}
}
