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

module hunt.view.render;

import std.string;
import std.file;
import std.path;
import std.conv;
import std.variant;
import std.json;
import std.stdio;
import std.uni;
import std.functional;

import kiss.logger;

import hunt.view.rule;
import hunt.view.element;
import hunt.view.match;
import hunt.view.ast;
import hunt.view.util;

import hunt.routing;
import hunt.simplify;

class Render
{
public:
    this()
    {
    }

    bool execCmp(T)(T a, T b, Function func)
    {
        //writeln("--------exec cmp : ", func);
        switch (func)
        {
        case Function.Equal:
            {
                return binaryFun!("a == b")(a, b);
            }
        case Function.Greater:
            {
                return binaryFun!("a > b")(a, b);
            }
        case Function.Less:
            {
                return binaryFun!("a < b")(a, b);
            }
        case Function.GreaterEqual:
            {
                return binaryFun!("a >= b")(a, b);
            }
        case Function.LessEqual:
            {
                return binaryFun!("a <= b")(a, b);
            }
        case Function.Different:
            {
                return binaryFun!("a != b")(a, b);
            }
        default:
            {
                return false;
            }
        }
    }

    bool cmp(JSONValue a, JSONValue b, Function func)
    {
       //writeln("--------cmp : ", func, " a type :", a.type, " b type :", b.type);

        if (a.type == JSON_TYPE.OBJECT || a.type == JSON_TYPE.ARRAY)
            return false;
        else if (a.type == JSON_TYPE.STRING)
        {
            if (a.type != b.type)
                return false;
            return execCmp!string(a.str, b.str, func);
        }
        else if (a.type == JSON_TYPE.INTEGER)
        {
            //writeln("a :",a.integer,"b :", b.integer);
            if (b.type == JSON_TYPE.INTEGER)
                return execCmp!long(a.integer, b.integer, func);
            else if (b.type == JSON_TYPE.UINTEGER)
            {
                return execCmp!long(a.integer, b.uinteger, func);
            }
            else
                return false;
        }
        else if (a.type == JSON_TYPE.UINTEGER)
        {
            if (b.type == JSON_TYPE.INTEGER)
                return execCmp!long(a.uinteger, b.integer, func);
            else if (b.type == JSON_TYPE.UINTEGER)
            {
                return execCmp!long(a.uinteger, b.uinteger, func);
            }
            else
                return false;
        }
        else if (a.type == JSON_TYPE.TRUE)
        {
            return true;
        }
        else if (a.type == JSON_TYPE.FALSE)
        {
            return true;
        }
        else
            return false;
    }

    bool eval(JSONValue j)
    {
        if (j.type == JSON_TYPE.OBJECT || j.type == JSON_TYPE.ARRAY)
            return true;
        else if (j.type == JSON_TYPE.STRING)
        {
            return j.str.length > 0 ? true : false;
        }
        else if (j.type == JSON_TYPE.INTEGER)
        {
            return j.integer > 0 ? true : false;
        }
        else if (j.type == JSON_TYPE.TRUE)
        {
            return true;
        }
        else if (j.type == JSON_TYPE.FALSE)
        {
            return false;
        }
        else
            return true;
    }

    T read_json(T = JSONValue)(JSONValue data, string command)
    {
        //writeln("------read json---- :", data.toString, "  command : ", command);
        T result;
        if (data.type == JSON_TYPE.OBJECT)
        {
            auto obj = command in data;
            if (obj !is null)
            {
                result = data[command];
            }
            else
            {
                auto cmds = split(command, ".");
                if (cmds.length > 1)
                {
                    auto first = cmds[0];
                    auto remain_cmd = command[first.length + 1 .. $];
                    // writeln("------remain cmd---- :", remain_cmd);
                    if (first in data)
                        result = read_json(data[first], remain_cmd);
                    else
                        template_engine_throw("render_error", "variable '" ~ first ~ "' not found");

                }
            }
            return result;
        }
        else if (data.type == JSON_TYPE.ARRAY)
        {
            if (Util.is_num(command))
                return data[to!int(command)];
            else
            {
                auto cmds = split(command, ".");
                if (cmds.length > 1)
                {
                    auto first = cmds[0];
                    auto remain_cmd = command[first.length + 1 .. $];
                    // writeln("------remain cmd---- :", remain_cmd);
                    if (Util.is_num(first))
                        result = read_json(data[to!int(first)], remain_cmd);
                    else
                        template_engine_throw("render_error", "variable '" ~ first ~ "' not found");

                }
            }
            return result;
        }
        else
        {
            return data;
        }
    }

    T eval_expression(T = JSONValue)(ElementExpression element, ref JSONValue data)
    {
        auto var = eval_function!(T)(element, data);
        return var;
    }

    T eval_function(T = JSONValue)(ElementExpression element, ref JSONValue data)
    {
        T result;
        //writeln("------element.func---- :", element.func);
        switch (element.func)
        {

        case Function.Upper:
            {
                auto res = eval_expression(element.args[0], data);
                if (res.type == JSON_TYPE.STRING)
                    result = toUpper(res.str);
                else
                    result = toUpper(res.toString);
                return result;
            }
        case Function.Lower:
            {
                auto res = eval_expression(element.args[0], data);
                if (res.type == JSON_TYPE.STRING)
                    result = toLower(res.str);
                else
                    result = toLower(res.toString);
                return result;
            }
        case Function.Equal:
        case Function.Greater:
        case Function.Less:
        case Function.GreaterEqual:
        case Function.LessEqual:
        case Function.Different:
            {
                result = cmp(eval_expression(element.args[0], data),
                        eval_expression(element.args[1], data), element.func);
                return result;
            }
        case Function.Int:
            {
                auto res = eval_expression(element.args[0], data);
                if (res.type == JSON_TYPE.STRING)
                {
                    if (Util.is_num(res.str))
                        result = to!int(res.str);
                }
                else
                {
                    if (Util.is_num(res.toString))
                        result = to!int(res.toString);
                }
                return result;
            }
        case Function.ReadJson:
            {
                try
                {
                    result = read_json(data, element.command);
                    return result;
                }
                catch (Exception e)
                {
                    template_engine_throw("render_error",
                            "variable '" ~ element.command ~ "' not found");
                }
                break;
            }
        case Function.Result:
            {
                writeln("--read result --:", element.result.toString);
                result = element.result;
                return result;
            }
        case Function.Length:
            {
                auto res = eval_expression(element.args[0], data);
                if (res.type == JSON_TYPE.STRING)
                    result = res.str.length;
                else if (res.type == JSON_TYPE.ARRAY)
                    result = res.array.length;
                else
                    result = 0;
                return result;
            }
        case Function.Range:
            {
                auto arg0 = eval_expression(element.args[0], data);
                auto arg1 = eval_expression(element.args[1], data);
                JSONValue[] ar;
                if (arg0.type == JSON_TYPE.INTEGER && arg1.type == JSON_TYPE.INTEGER)
                {
                    for (long i = arg0.integer; i <= arg1.integer; i++)
                        ar ~= JSONValue(i);
                }

                result = ar;

                return result;
            }
        case Function.Sort:
            {
                auto res = eval_expression(element.args[0], data);
                long[] sa_l;
                string[] sa_s;
                if (res.type == JSON_TYPE.ARRAY)
                {
                    import std.algorithm.sorting;

                    foreach (size_t k, v; res)
                    {
                        if (v.type == JSON_TYPE.INTEGER)
                            sa_l ~= v.integer;
                        else if (v.type == JSON_TYPE.STRING)
                            sa_s ~= v.str;
                    }
                    if (sa_l.length > 0)
                    {
                        sort!("a < b")(sa_l);
                        result = JSONValue(sa_l);
                    }
                    else
                    {
                        sort!("a < b")(sa_s);
                        result = JSONValue(sa_s);
                    }
                }
                return result;
            }
        case Function.DateFormat:
            {
                auto format = eval_expression(element.args[0], data);
                auto timestamp = eval_expression(element.args[1], data);
                if (format.type == JSON_TYPE.STRING && timestamp.type == JSON_TYPE.INTEGER)
                {
                    import kiss.datetime;

                    result = date(format.str, timestamp.integer);
                }
                return result;
            }
        case Function.Url:
            {
                auto mca = eval_expression(element.args[0], data);
                auto params = eval_expression(element.args[1], data);
                if (mca.type == JSON_TYPE.STRING && params.type == JSON_TYPE.STRING)
                {
                    result = createUrl(mca.str, Util.parseFormData(params.str), _routeGroup);
                }
                return result;
            }
        case Function.IsNull:
            {
                auto res = eval_expression(element.args[0], data);
                result = res.isNull;
                return result;
            }
        case Function.Default:
            {
                //writeln("-----Function.Default----");
                try
                {
                    return eval_expression!(T)(element.args[0], data);
                }
                catch (Exception e)
                {
                    template_engine_throw("render_error",
                            "function '" ~ to!string(element.func) ~ "' not found");
                }
            }
        default:
            {
                template_engine_throw("render_error",
                        "function '" ~ to!string(element.func) ~ "' not found");
            }
        }

        template_engine_throw("render_error", "unknown function in render: " ~ element.command);
        return T();
    }

    string render(ASTNode temp, ref JSONValue data)
    {
        string result = "";
        //writeln("------temp.parsed_node.children-----: ",temp.parsed_node.children.length);
        foreach (element; temp.parsed_node.children)
        {
            //writeln("------element.type-----: ",element.type);
            switch (element.type)
            {
            case Type.String:
                {
                    auto element_string = cast(ElementString)(element);
                    result ~= element_string.text;
                    break;
                }
            case Type.Expression:
                {
                    auto element_expression = cast(ElementExpression)(element);
                    auto variable = eval_expression(element_expression, data);

                    // writeln("-----variable.type-------: ",variable.type);
                    if (variable.type == JSON_TYPE.STRING)
                    {
                        result ~= variable.str;
                    }
                    else
                    {

                        result ~= variable.toString;
                    }
                    break;
                }
            case Type.Loop:
                {
                    auto element_loop = cast(ElementLoop)(element);
                    switch (element_loop.loop)
                    {
                    case Loop.ForListIn:
                        {
                            auto list = eval_expression(element_loop.list, data);
                            //writeln("----list ----: ", list);
                            if (list.type != JSON_TYPE.ARRAY)
                            {
                                template_engine_throw("render_error",
                                        list.toString ~ " is not an array");
                            }
                            foreach (size_t k, v; list)
                            {
                                //writeln("v.type : ",v.type, " v.tostring :",v.toString);
                                JSONValue data_loop = parseJSON(data.toString);
                                data_loop["index"] = k;
                                data_loop[element_loop.value] = v;
                                result ~= render(new ASTNode(element_loop), data_loop);
                            }
                            break;
                        }
                    case Loop.ForMapIn:
                        {
                            auto map = eval_expression(element_loop.list, data);
                            //writeln("----Loop type ----: ", map.type," map.toString : ",map.toString);
                            if (map.type == JSON_TYPE.OBJECT)
                            {
                                foreach (string k, v; map)
                                {
                                    JSONValue data_loop = data;
                                    data_loop[element_loop.key] = k;
                                    data_loop[element_loop.value] = v;
                                    result ~= render(new ASTNode(element_loop), data_loop);
                                }
                            }
                            else if (map.type == JSON_TYPE.ARRAY)
                            {
                                foreach (size_t idx, v; map)
                                {
                                    JSONValue data_loop = data;
                                    data_loop[element_loop.key] = idx;
                                    data_loop[element_loop.value] = v;
                                    result ~= render(new ASTNode(element_loop), data_loop);
                                }
                            }
                            else
                            {
                                template_engine_throw("render_error",
                                        map.toString ~ " is not an array or object");
                            }
                            break;
                        }
                    default:
                        {
                            break;
                        }
                    }

                    break;
                }
            case Type.Condition:
                {
                    auto element_condition = cast(ElementConditionContainer)(element);
                    foreach (branch; element_condition.children)
                    {
                        auto element_branch = cast(ElementConditionBranch)(branch);
                        //writeln("-----element_branch.type-------: ",element_branch.condition_type);
                        auto flg = eval_expression(element_branch.condition, data);
                        //writeln("-----flg.type-------: ",flg.type);
                        if (element_branch.condition_type == Condition.Else || eval(flg))
                        {
                            result ~= render(new ASTNode(element_branch), data);
                            break;
                        }
                    }
                    break;
                }
            default:
                {
                    break;
                }
            }
        }
        return result;
    }

    public void setRouteGroup(string rg)
    {
        _routeGroup = rg;
    }

private:
    string _routeGroup = DEFAULT_ROUTE_GROUP;
}
