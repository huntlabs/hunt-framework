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

module hunt.view.rule;

import std.regex;
import std.exception;
import std.string;

import hunt.view.match;

void template_engine_throw(string type, string message) {
	throw new Exception("[Template Engine exception." ~ type ~ "] " ~ message);
}

enum  Type {
	Comment,
	Condition,
	ConditionBranch,
	Expression,
	Loop,
	Main,
	String
}

enum  Delimiter {
	Comment,
	Expression,
	LineStatement,
	Statement
}

enum  Statement {
	Condition,
	Include,
	Loop
}

//the order is import(maximum match)
enum  Function {
	Not,
	And,
	Or,
	In,
	Equal,
	GreaterEqual,
	Greater,
	LessEqual,
	Less,
	Different,
	Callback,
	DivisibleBy,
	Even,
	First,
	Float,
	Int,
	Last,
	Length,
	Lower,
	Max,
	Min,
	Odd,
	Range,
	Result,
	Round,
	Sort,
	Upper,
	DateFormat,
	Url,
	ReadJson,
	Default
}

enum  Condition {
	ElseIf,
	If,
	Else 
}

enum  Loop {
	ForListIn,
	ForMapIn
}

static this()
{
	regex_map_delimiters = [
		Delimiter.Statement :  ("\\{\\%\\s*(.+?)\\s*\\%\\}"),
		Delimiter.LineStatement: ("(?:^|\\n)## *(.+?) *(?:\\n|$)"),
		Delimiter.Expression : ("\\{\\{\\s*(.+?)\\s*\\}\\}"),
		Delimiter.Comment: ("\\{#\\s*(.*?)\\s*#\\}")
	];
}

__gshared string[Delimiter] regex_map_delimiters;

enum string[Statement] regex_map_statement_openers = [
	Statement.Loop : ("for \\s*(.+)"),
	Statement.Condition : ("if \\s*(.+)"),
	Statement.Include : ("include \\s*\"(.+)\"")
];

enum string[Statement] regex_map_statement_closers = [
	Statement.Loop : ("endfor"),
	Statement.Condition : ("endif")
];

enum string[Loop] regex_map_loop = [
	Loop.ForListIn : ("for (\\w+) in (.+)"),
	Loop.ForMapIn : ("for (\\w+),\\s*(\\w+) in (.+)")
];

enum string[Condition] regex_map_condition = [
	Condition.If : ("if \\s*(.+)"),
	Condition.ElseIf : ("else if \\s*(.+)"),
	Condition.Else : ("else")
];

string function_regex(const string name, int number_arguments) {
	string pattern = name;
	pattern ~= "(?:\\(";
	for (int i = 0; i < number_arguments; i++) {
		if (i != 0) pattern ~= ",";
		pattern ~= "(.*)";
	}
	pattern ~= "\\))";
	if (number_arguments == 0) { // Without arguments, allow to use the callback without parenthesis
		pattern ~= "?";
	}
	return "\\s*" ~ pattern ~ "\\s*";
}

enum string[Function] regex_map_functions = [
	Function.Not : "not (.+)",
	Function.And : "(.+) and (.+)",
	Function.Or : "(.+) or (.+)",
	Function.In : "(.+) in (.+)",
	Function.Equal : "(.+)\\s*==\\s*(.+)",
	Function.Greater : "(.+)\\s*>\\s*(.+)",
	Function.Less : "(.+)\\s*<\\s*(.+)",
	Function.GreaterEqual : "(.+)\\s*>=\\s*(.+)",
	Function.LessEqual : "(.+)\\s*<=\\s*(.+)",
	Function.Different : "(.+)\\s*!=\\s*(.+)",
	Function.Default : function_regex("default", 2),
	Function.DivisibleBy : function_regex("divisibleBy", 2),
	Function.Even : function_regex("even", 1),
	Function.First : function_regex("first", 1),
	Function.Float : function_regex("float", 1),
	Function.Int : function_regex("int", 1),
	Function.Last : function_regex("last", 1),
	Function.Length : function_regex("length", 1),
	Function.Lower : function_regex("lower", 1),
	Function.Max : function_regex("max", 1),
	Function.Min : function_regex("min", 1),
	Function.Odd : function_regex("odd", 1),
	Function.Range : function_regex("range", 2),
	Function.Round : function_regex("round", 2),
	Function.Sort : function_regex("sort", 1),
	Function.Upper : function_regex("upper", 1),
	Function.DateFormat : function_regex("date", 2),
	Function.Url : function_regex("url", 2),
	Function.ReadJson : "\\s*([^\\(\\)]*\\S)\\s*"
];

enum ElementNotation {
	Dot,
	Pointer
};