
module hunt.web.router.utils;

import std.string;
import std.regex;
import std.traits;

void controllerHelper(string FUN, T, REQ, RES)(string str, REQ req, RES res) if (
        (is(T == class) || is(T == interface)) && hasMember!(T, FUN))
{
    import std.experimental.logger;

    auto index = lastIndexOf(str, '.');
    if (index < 0 || index == (str.length - 1))
    {
        error("can not find function!, the str is  : ", str);
        return;
    }

    string objName = str[0 .. index];
    string funName = str[(index + 1) .. $];

    auto obj = Object.factory(objName);
    if (!obj)
    {
        error("Object.factory erro!, the obj Name is : ", objName);
        return;
    }
    auto a = cast(T) obj;
    if (!a)
    {
        error("cast(T)obj; erro!");
        return;
    }

    mixin("a." ~ FUN ~ "(funName,req,res);");
}

version (unittest)
{
    import std.stdio;

    interface A
    {
        void show(string str, int i, int b);
    }

    class AA : A
    {
        override void show(string str, int i, int b)
        {
            writeln("the function name is : ", str);
            writeln("i = ", i, "  b = ", b);
        }
    }
}

unittest
{
    controllerHelper!("show", A, int, int)("hunt.web.router.utils.AA.show", 1, 4);
    controllerHelper!("show", AA, int, int)("hunt.web.router.utils.AA.show", 2, 8);
}

/// 构造正则表达式，类似上个版本的，把配置里的单独的表达式，构建成一个
string buildRegex(string reglist)
{
    string[] list = split(reglist, "/");
    string regexd;

    bool handleRegex(string str)
    {
        regexd ~= "(";
        auto site = indexOf(str, ':');
        if (site < 0)
            return false;
        if (site > 0)
        {
            regexd ~= "?P<";
            regexd ~= str[0 .. site];
            regexd ~= ">";
        }
        regexd ~= str[(site + 1) .. $];
        regexd ~= ")";
        return true;
    }

    bool regexBuild(string str)
    {
        if (str.length == 0)
            return true;
        regexd ~= r"\/";
        auto frist = indexOf(str, '{');
        auto last = lastIndexOf(str, "}");
        if (frist < 0 || last < 0)
            return false;
        if (frist > 0)
            regexd ~= str[0 .. frist];

        if (!handleRegex(str[(frist + 1) .. last]))
            return false;
        if (last + 1 < str.length)
            regexd ~= str[(last + 1) .. $];
        return true;
    }

    foreach (ref str; list)
    {
        if (!regexBuild(str))
            return "";
    }
    return regexd;
}

unittest
{
    import std.stdio;

    string reglist = "/{:[0-9a-z]{1}}/{d2:[0-9a-z]{2}}/{imagename:\\w+\\.\\w+}";
    string reg = buildRegex(reglist);

    writeln("\n\n the regex is  : ", reg);
    auto r = regex(reg);
    writeln("this regex is : ", !r.empty);
    assert(reg.length > 0);

    reglist = "/{abc:[0-9a-z]{1}}/{imagename:\\w+\\.\\w+}";
    reg = buildRegex(reglist);

    writeln("\n\n the regex is  : ", reg);
    r = regex(reg);
    writeln("this regex is : ", !r.empty);
    assert(reg.length > 0);

    reglist = "/{[0-9a-z]{1}}/{imagename:\\w+\\.\\w+}";
    reg = buildRegex(reglist);

    writeln("\n\n the regex is  : ", reg);
    r = regex(reg);
    writeln("this regex is : ", !r.empty);
    assert(reg.length == 0);

    reglist = "/serew{:[0-9a-z]{1}}/{imagename:\\w+\\.\\w+}444";
    reg = buildRegex(reglist);

    writeln("\n\n the regex is  : ", reg);
    r = regex(reg);
    writeln("this regex is : ", !r.empty);
    assert(reg.length > 0);
}

/// 判断URL中是否是正则表达式的 (是否有{字符)
bool isHaveRegex(string path)
{
    if (path.indexOf('{') < 0 && path.indexOf('}') < 0)
        return false;
    else
        return true;
}

/// file
/// 取出来地一个path： 例如： /file/ddd/f ; reurn = file,  lpath= /ddd/f;
string getFirstPath(string fpath, out string lpath)
{
    if (fpath.length == 0)
        return "";
    if (fpath[0] == '/')
    {
        fpath = fpath[1 .. $];
    }

    auto sprit_pos = fpath.indexOf('/');

    if (sprit_pos < 0)
        return fpath;

    lpath = fpath[sprit_pos .. $];
    return fpath[0 .. sprit_pos];
}

unittest
{
    string path = "/s/d/fwww/";
    string lpath;
    path = getFristPath(path, lpath);
    assert(path == "s");
    assert(lpath == "/d/fwww/");

    path = getFristPath(lpath, lpath);
    assert(path == "d");
    assert(lpath == "/fwww/");

    path = getFristPath(lpath, lpath);
    assert(path == "fwww");
    assert(lpath == "/");

    path = getFristPath(lpath, lpath);
    assert(path == "");
    assert(lpath == "");
}
