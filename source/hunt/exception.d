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

module hunt.exception;

import std.exception;
import collie.utils.exception;

mixin ExceptionBuild!("Hunt","");

class NotImplementedException : Exception
{
    this(string method)
    {
        super(method ~ " is not implemented");
    }
}