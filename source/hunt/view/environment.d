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

module hunt.view.environment;

import std.string;
import std.json;
import std.file;
import std.path;
import std.stdio;

import kiss.logger;
import hunt.application.config;
import hunt.view.match;
import hunt.view.rule;
import hunt.view.parser;
import hunt.view.render;
import hunt.view.util;
import hunt.view.ast;

class Environment
{
    private
    {
        string input_path;
        string output_path;

        Parser _parser;
        Render _render;
    }

public:
    this()
    {
        auto tpl_path = Config.app.view.path;
        if(tpl_path.length == 0)
            tpl_path = "./views/";
        input_path = output_path = buildNormalizedPath(tpl_path) ~ dirSeparator;
        _parser = new Parser();
        _render = new Render();
    }

    this(string global_path)
    {
        input_path = output_path = buildNormalizedPath(global_path) ~ dirSeparator;
        //writeln("input path : ",input_path);
        _parser = new Parser();
        _render = new Render();
    }

    this(string input_path, string output_path)
    {
        this.input_path = buildNormalizedPath(input_path) ~ dirSeparator;
        this.output_path = buildNormalizedPath(output_path) ~ dirSeparator;
        _parser = new Parser();
        _render = new Render();
    }

    void setTemplatePath(string path)
    {
        this.input_path = buildNormalizedPath(path) ~ dirSeparator;
    }

    void set_statement(string open, string close)
    {
        regex_map_delimiters[Delimiter.Statement] = open ~ "\\s*(.+?)\\s*" ~ close;
    }

    void set_line_statement(string open)
    {
        regex_map_delimiters[Delimiter.LineStatement] = "(?:^|\\n)" ~ open ~ " *(.+?) *(?:\\n|$)";
    }

    void set_expression(string open, string close)
    {
        regex_map_delimiters[Delimiter.Expression] = open ~ "\\s*(.+?)\\s*" ~ close;
    }

    void set_comment(string open, string close)
    {
        regex_map_delimiters[Delimiter.Comment] = open ~ "\\s*(.+?)\\s*" ~ close;
    }

    void set_element_notation(ElementNotation element_notation_)
    {
        _parser.element_notation = element_notation_;
    }

    ASTNode parse(string input)
    {
        return _parser.parse(input);
    }

    ASTNode parse_template(string filename)
    {
        trace("parse file path : ",input_path ~ filename);
        return _parser.parse_template(input_path ~ filename);
    }

    string render(string input, JSONValue data)
    {
        return _render.render(parse(input), data);
    }

    string render(ASTNode temp, JSONValue data)
    {
        return _render.render(temp, data);
    }

    string render_file(string filename, JSONValue data)
    {
        return _render.render(parse_template(filename), data);
    }

    string render_file_with_json_file(string filename, string filename_data)
    {
        auto data = load_json(filename_data);
        return render_file(filename, data);
    }

    void write(string filename, JSONValue data, string filename_out) {
        std.file.write(output_path ~ filename_out,render_file(filename,data));
    }

    void write(ASTNode temp, JSONValue data, string filename_out) {
    	std.file.write(output_path ~ filename_out,render(temp,data));
    }

    void write_with_json_file(string filename, string filename_data, string filename_out) {
    	auto data = load_json(filename_data);
    	write(filename, data, filename_out);
    }

    void write_with_json_file(ASTNode temp, string filename_data, string filename_out) {
    	auto data = load_json(filename_data);
    	write(temp, data, filename_out);
    }

    string load_global_file(string filename)
    {
        return _parser.load_file(input_path ~ filename);
    }

    JSONValue load_json(string filename)
    {
        return parseJSON(cast(string) std.file.read(input_path ~ filename));
    }
};
