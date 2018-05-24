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

module hunt.view.util;

import hunt.view.element;
import hunt.view.rule;
import std.stdio;
import std.regex;

class Util
{
    static int level = 1;
public:
    static void debug_ast(Element e)
    {
        level++;
        switch (e.type)
        {
        case Type.Comment:
            {
                auto elm = cast(ElementComment)(e);
                printSpace(level);
                writeln("Type : Comment,  text : ", elm.text);
                break;
            }
        case Type.Condition:
            {
                auto elm = cast(ElementConditionContainer)(e);
                printSpace(level);
                writeln("Type : Condition ");
                printSpace(level);
                writeln("       +++++++children begin ");
                foreach (child; elm.children)
                {
                    debug_ast(child);
                }
                printSpace(level);
                writeln("       +++++++children end ");
                break;
            }
        case Type.ConditionBranch:
            {
                auto elm = cast(ElementConditionBranch)(e);
                printSpace(level);
                writeln("Type : ConditionBranch,  condition_type : ", elm.condition_type);
                printSpace(level);
                writeln("       ElementExpression begin ");
                debug_ast(elm.condition);
                printSpace(level);
                writeln("       ElementExpression end ");
                printSpace(level);
                writeln("       +++++++children begin ");
                foreach (child; elm.children)
                {
                    debug_ast(child);
                }
                printSpace(level);
                writeln("       +++++++children end ");
                break;
            }
        case Type.Expression:
            {
                auto elm = cast(ElementExpression)(e);
                printSpace(level);
                writeln("Type : Expression,  Function : ", elm.func,
                        ", command :", elm.command, ", result :", elm.result.toString);
                printSpace(level);
                writeln("       =====args begin=====");
                foreach (child; elm.args)
                {
                    debug_ast(child);
                }
                printSpace(level);
                writeln("       =====args end=======");
                printSpace(level);
                writeln("       +++++++children begin ");
                foreach (child; elm.children)
                {
                    debug_ast(child);
                }
                printSpace(level);
                writeln("       +++++++children end ");
                break;
            }
        case Type.Loop:
            {
                auto elm = cast(ElementLoop)(e);
                printSpace(level);
                writeln("Type : Loop,  Loop : ", elm.loop, " key:", elm.key,
                        " value: ", elm.value);
                printSpace(level);
                writeln("       ElementExpression begin ");
                debug_ast(elm.list);
                printSpace(level);
                writeln("       ElementExpression end ");
                printSpace(level);
                writeln("       +++++++children begin ");
                foreach (child; elm.children)
                {
                    debug_ast(child);
                }
                printSpace(level);
                writeln("       +++++++children end ");
                break;
            }
        case Type.Main:
            {
                printSpace(level);
                writeln("----------AST TREE DEBUG-----------");
                foreach (child; e.children)
                {
                    debug_ast(child);
                }
                break;
            }
        case Type.String:
            {
                auto elm = cast(ElementString)(e);
                printSpace(level);
                writeln("Type : String,  text : ", elm.text);
                break;
            }
        default:
            {
                break;
            }
        }

        level--;
    }

    static printSpace(int num)
    {
        for (size_t i = 0; i < num; i++)
            write("       ");
    }

    static bool is_num(string str)
    {
        auto m = match(str, regex(`^[0-9]\d*$`));
        return !m.empty;
    }
}
