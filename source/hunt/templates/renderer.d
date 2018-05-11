module hunt.templates.renderer;

import std.string;
import std.file;
import std.path;
import std.conv;
import std.variant;
import std.json;
import std.stdio;
import std.uni;
import std.functional;

import hunt.templates.rule;
import hunt.templates.element;
import hunt.templates.match;
import hunt.templates.ast;
import hunt.templates.util;

class Renderer
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
        //writeln("--------cmp : ", func, " a type :", a.type);
        if (a.type != b.type)
            return false;
        if (a.type == JSON_TYPE.OBJECT || a.type == JSON_TYPE.ARRAY)
            return false;
        else if (a.type == JSON_TYPE.STRING)
        {
            return execCmp!string(a.str, b.str, func);
        }
        else if (a.type == JSON_TYPE.INTEGER)
        {
            return execCmp!long(a.integer, b.integer, func);
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
        case Function.ReadJson:
            {
                try
                {
                    //writeln("--read * json --:", element.command);
                    if (element.command.length > 0 && element.command in data)
                        result = data[element.command];
                    else
                    {
                        auto cmds = split(element.command, ".");
                        if (cmds.length > 1)
                        {
                            if (cmds.length == 2)
                            {
                                if (cmds[0] in data)
                                {
                                    if (Util.is_num(cmds[1]))
                                    {
                                        auto idx = to!int(cmds[1]);

                                        result = data[cmds[0]][idx];
                                    }
                                    else if (cmds[1] in data[cmds[0]])
                                        result = data[cmds[0]][cmds[1]];
                                }

                            }
                        }
                        else
                            result = element.command;
                    }
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
                //writeln("--read result --:", element.result.toString);
                result = element.result;
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
                    return eval_expression!(T)(element.args[1], data);
                }
            }
        default:
            {
                template_engine_throw("render_error",
                        "function '" ~ to!string(element.func) ~ "' not found");
            }
        }

        template_engine_throw("render_error", "unknown function in renderer: " ~ element.command);
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
                            if (map.type != JSON_TYPE.OBJECT)
                            {
                                template_engine_throw("render_error",
                                        map.toString ~ " is not an object");
                            }
                            foreach (string k, v; map)
                            {
                                JSONValue data_loop = data;
                                data_loop[element_loop.key] = k;
                                data_loop[element_loop.value] = v;
                                result ~= render(new ASTNode(element_loop), data_loop);
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
}
