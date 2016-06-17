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
module hunt.application.controller;

public import hunt.http.response;
public import hunt.http.request;

interface IController
{
    bool __CALLACTION__(string method, Request req,  Response res);
}

mixin template HuntDynamicCallFun()
{
    mixin(_createCallActionFun!(typeof(this)));
}

string  _createCallActionFun(T)()
{
    import std.traits;
    import std.typecons;
    string str = "override bool __CALLACTION__(string funName,Request req,  Response res) {";
    str ~= "switch(funName){";
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            foreach (t;__traits(getOverloads,T,memberName)) 
            {
                Parameters!(t) functionArguments;
                static if(functionArguments.length == 2 && is(typeof(functionArguments[0]) == Request) && is(typeof(functionArguments[1]) == Response))
                {
                    str ~= "case \"";
                    str ~= memberName;
                    str ~= "\":";
                    str = str ~  memberName ~ "(req,res); return true;";
                }
            }
        }
    }
    str ~= "default : return false;}";
    str ~= "}";
    return str;
}
