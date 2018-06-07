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

module hunt.view.parser;

import std.string;
import std.file;
import std.path;
import std.conv;
import std.stdio;

import hunt.view.rule;
import hunt.view.element;
import hunt.view.match;
import hunt.view.ast;
import hunt.view.util;
import hunt.view.cache;

class Parser
{
public:
    ElementNotation element_notation = ElementNotation.Pointer;

    this()
    {
    }

    ElementExpression parse_expression(const string input)
    {

        if (input.length <= 0)
            return new ElementExpression(Function.ReadJson);
        auto match_function = RegexObj.match!Function(input, regex_map_functions);
        switch (match_function.type())
        {
        case Function.ReadJson:
            {
                string command = match_function.str(1);

                if ((startsWith(command, '"') && endsWith(command, '"'))
                        || (startsWith(command, '\'') && endsWith(command, '\'')))
                { //  Result
                    ElementExpression result = new ElementExpression(Function.Result);
                    result.result = command[1 .. $ - 1];
                    return result;
                }

                if(Util.is_num(command))
                {
                    ElementExpression result = new ElementExpression(Function.Result);
                    result.result = to!int(command);
                    return result;
                }

                ElementExpression result = new ElementExpression(Function.ReadJson);
                switch (element_notation)
                {
                case ElementNotation.Pointer:
                    {
                        //if (command[0] != '/') { command = "/"~command; }
                        result.command = command;
                        break;
                    }
                case ElementNotation.Dot:
                    {
                        result.command = command;
                        break;
                    }
                default:
                    template_engine_throw("parser_error",
                            "element notation: " ~ element_notation.stringof);
                    break;
                }
                return result;
            }
        default:
            {
                ElementExpression[] args;
                for (int i = 1; i < match_function.size(); i++)
                { // str(0) is whole group
                    args ~= parse_expression(match_function.str(i));
                }

                ElementExpression result = new ElementExpression(match_function.type());
                result.args = args;
                return result;
            }
        }
    }

    Element[] parse_level(string input, string path)
    {
        Element[] result;

        size_t current_position = 0;
        auto match_delimiter = RegexObj.search_all(input, current_position);
        //writeln("-----3------");
        while (match_delimiter.found())
        {
            current_position = match_delimiter.end_position();
            //writeln("---whole --- :",match_delimiter.str());
            string string_prefix = match_delimiter.prefix();
            if (!string_prefix.empty())
            {
                result ~= new ElementString(string_prefix);
            }

            string delimiter_inner = match_delimiter.str(1);

            switch (match_delimiter.type())
            {
            case Delimiter.Statement:
            case Delimiter.LineStatement:
                {

                    auto match_statement = RegexObj.match!Statement(delimiter_inner,
                            regex_map_statement_openers);
                    switch (match_statement.type())
                    {
                    case Statement.Loop:
                        {
                            MatchClosed loop_match = RegexObj.search_closed(input,
                                    match_delimiter.pattern(), regex_map_statement_openers[Statement.Loop],
                                    regex_map_statement_closers[Statement.Loop], match_delimiter);

                            current_position = loop_match.end_position();

                            string loop_inner = match_statement.str(0);
                            auto match_command = RegexObj.match!Loop(loop_inner, regex_map_loop);
                            if (!match_command.found())
                            {
                                template_engine_throw("parser_error",
                                        "unknown loop statement: " ~ loop_inner);
                            }
                            //writeln("#############match type :",match_command.type());
                            switch (match_command.type())
                            {
                            case Loop.ForListIn:
                                {
                                    string value_name = match_command.str(1);
                                    string list_name = match_command.str(2);
                                    result ~= new ElementLoop(match_command.type(), value_name,
                                            parse_expression(list_name), loop_match.inner());
                                    break;
                                }
                            case Loop.ForMapIn:
                                {
                                    string key_name = match_command.str(1);
                                    string value_name = match_command.str(2);
                                    string list_name = match_command.str(3);

                                    result ~= new ElementLoop(match_command.type(), key_name, value_name,
                                            parse_expression(list_name), loop_match.inner());
                                    break;
                                }
                            default:
                                template_engine_throw("parser_error",
                                        "unknown loop statement: " ~ match_command.str());
                                break;
                            }
                            break;
                        }
                    case Statement.Condition:
                        {
                            auto condition_container = new ElementConditionContainer();

                            Match condition_match = match_delimiter;
                            MatchClosed else_if_match = RegexObj.search_closed_on_level(input,
                                    match_delimiter.pattern(),
                                    regex_map_statement_openers[Statement.Condition],
                                    regex_map_statement_closers[Statement.Condition],
                                    regex_map_condition[Condition.ElseIf], condition_match);
                            while (else_if_match.found())
                            {
                                condition_match = else_if_match._close_match;

                                string else_if_match_inner = else_if_match._open_match.str(1);
                                auto match_command = RegexObj.match!Condition(else_if_match_inner,
                                        regex_map_condition);
                                if (!match_command.found())
                                {
                                    template_engine_throw("parser_error",
                                            "unknown if statement: " ~ else_if_match._open_match.str());
                                }
                                condition_container.children ~= new ElementConditionBranch(else_if_match.inner(),
                                        match_command.type(),
                                        parse_expression(match_command.str(1)));

                                else_if_match = RegexObj.search_closed_on_level(input, match_delimiter.pattern(),
                                        regex_map_statement_openers[Statement.Condition],
                                        regex_map_statement_closers[Statement.Condition],
                                        regex_map_condition[Condition.ElseIf], condition_match);
                            }

                            MatchClosed else_match = RegexObj.search_closed_on_level(input, match_delimiter.pattern(),
                                    regex_map_statement_openers[Statement.Condition],
                                    regex_map_statement_closers[Statement.Condition],
                                    regex_map_condition[Condition.Else], condition_match);
                            if (else_match.found())
                            {
                                condition_match = else_match._close_match;

                                string else_match_inner = else_match._open_match.str(1);
                                auto match_command = RegexObj.match!Condition(else_match_inner,
                                        regex_map_condition);
                                if (!match_command.found())
                                {
                                    template_engine_throw("parser_error",
                                            "unknown if statement: " ~ else_match._open_match.str());
                                }
                                //writeln("################### :",match_command.str(1),"   else match inner : ",else_match_inner);
                                condition_container.children ~= new ElementConditionBranch(else_match.inner(),
                                        match_command.type(),
                                        parse_expression(match_command.str(1)));
                            }

                            MatchClosed last_if_match = RegexObj.search_closed(input, match_delimiter.pattern(),
                                    regex_map_statement_openers[Statement.Condition],
                                    regex_map_statement_closers[Statement.Condition],
                                    condition_match);
                            //MatchClosed last_if_match = RegexObj.search_closed_on_level(input, match_delimiter.pattern(), regex_map_statement_openers[Statement.Condition], regex_map_statement_closers[Statement.Condition], regex_map_statement_closers[Statement.Condition], condition_match);
                            if (!last_if_match.found())
                            {
                                writeln("--####- - : ",delimiter_inner);
                                template_engine_throw("parser_error", "unknown statement : " ~ delimiter_inner);
                            }

                            string last_if_match_inner = last_if_match._open_match.str(1);
                            auto match_command = RegexObj.match!Condition(last_if_match_inner,
                                    regex_map_condition);
                            if (!match_command.found())
                            {
                                template_engine_throw("parser_error",
                                        "unknown statement: " ~ last_if_match._open_match.str());
                            }
                            if (match_command.type() == Condition.Else)
                            {
                                //writeln("################### 1:",last_if_match.inner());
                                condition_container.children ~= new ElementConditionBranch(last_if_match.inner(),
                                        match_command.type());
                            }
                            else
                            {
                                //writeln("################### 2:",match_command.str(1));
                                condition_container.children ~= new ElementConditionBranch(last_if_match.inner(),
                                        match_command.type(),
                                        parse_expression(match_command.str(1)));
                            }

                            current_position = last_if_match.end_position();
                            result ~= condition_container;
                            break;
                        }
                    case Statement.Include:
                        {
                            string included_filename = path ~ match_statement.str(1);
                            writeln("----include file path : ",included_filename);
                            ASTNode included_template = parse_template(included_filename);
                            foreach (element; included_template.parsed_node.children)
                            {
                                result ~= element;
                            }
                            break;
                        }
                    default:
                        {
                            template_engine_throw("parser_error",
                                    "unknown  statement: " ~ to!string(match_statement.type()));
                            break;
                        }
                    }
                    break;
                }
            case Delimiter.Expression:
                {
                    result ~= parse_expression(delimiter_inner);
                    break;
                }
            case Delimiter.Comment:
                {
                    result ~= new ElementComment(delimiter_inner);
                    break;
                }
            default:
                {
                    template_engine_throw("parser_error",
                            "unknown  statement: " ~ to!string(match_delimiter.type()));
                    break;
                }
            }

            match_delimiter = RegexObj.search_all(input, current_position);
            //writeln("-----4------: ",current_position);
        }
        if (current_position < input.length)
        {
            result ~= new ElementString(input[current_position .. $]);
        }

        return result;
    }

    Element parse_tree(Element current_element, string path)
    {

        if (current_element.inner.length > 0)
        {
            //writeln("-----parse_level ------ : ", current_element.inner);
            current_element.children = parse_level(current_element.inner, path);
            current_element.inner = string.init;
        }

        if (current_element.children.length > 0)
        {
            for (size_t i = 0; i < current_element.children.length; i++)
            {
                //writeln("-----2------");
                auto em = current_element.children[i];
                //writeln("*******type : ",current_element.type);
                current_element.children[i] = parse_tree(em, path);
            }
        }
        return current_element;
    }

    ASTNode parse(string input)
    {
        auto parsed = parse_tree(new Element(Type.Main, input), "./");
        return new ASTNode(parsed);
    }

    ASTNode parse_template(string filename)
    {
        auto node = ASTCache.node(filename);
        if (node !is null)
            return node;

        string input = load_file(filename);
        string path = dirName(filename);
        //writeln("----template file path : ",filename);
        auto parsed = parse_tree(new Element(Type.Main, input), path ~ "/");
        auto astnode = new ASTNode(parsed);
        ASTCache.add(filename, astnode);
        return astnode;
    }

    string load_file(string filename)
    {
        return cast(string) std.file.read(filename);
    }
}
