module hunt.http.controller;

public import hunt.http.response;
public import hunt.http.request;

interface IController
{
    bool __CALLACTION__(string method, Request req,  Response res);
}

mixin template HuntDynamicCallFun()
{
    mixin(getListStr!(typeof(this)));
}

string  getListStr(T)()
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