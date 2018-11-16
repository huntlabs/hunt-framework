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

module hunt.framework.view.Match;

import std.regex;
import std.string;
import std.traits;
import std.stdio;
import std.conv;
import std.algorithm.sorting;

import hunt.framework.view.Rule;

class Match
{
	string _pattern;

public:
	this()
	{
	}

	this(string pattern)
	{
		_pattern = pattern;
	}

	void set_pattern(string pat)
	{
		_pattern = pat;
	}

	@property string pattern()
	{
		return _pattern;
	}

	string str(int i = 0)
	{
		return string.init;
	}

	string prefix()
	{
		writeln("-----debug------", __LINE__);
		return string.init;
	}

	string suffix()
	{
		writeln("-----debug------", __LINE__);
		return string.init;
	}

	size_t position()
	{
		writeln("-----debug------", __LINE__);
		return 0;
	}

	size_t end_position()
	{
		writeln("-----debug------", __LINE__);
		return 0;
	}

	bool found()
	{
		//writeln("-----debug------", __LINE__);
		return false;
	}
}

class MatchType(T, R = string) : Match
{
	T type_;
	RegexMatch!(R) _allm;
	Captures!(R) _firstm;
	size_t offset_ = 0;
public:
	this()
	{
		super();
	}

	this(size_t cur, string pattern = string.init)
	{
		super(pattern);
		offset_ = cur;
	}

	void setMatchResult(ref RegexMatch!(R) rm)
	{
		_allm = rm;
	}

	@property RegexMatch!(R) match()
	{
		return _allm;
	}

	void setMatchFirst(ref Captures!(R) fm)
	{
		_firstm = fm;
	}

	@property Captures!(R) firstMatch()
	{
		return _firstm;
	}

	void set_type(T type)
	{
		type_ = type;
	}

	@property T type() const
	{
		return type_;
	}

	@property bool empty()
	{
		return _allm.empty && _firstm.empty;
	}

	override bool found()
	{
		return !empty;
	}

	@property size_t size()
	{
		return _allm.front.length;
	}

	override string str(int i = 0)
	{
		if (i >= _allm.front.length)
			return string.init;
		return _allm.front[i];
	}

	override string prefix()
	{
		return _allm.front.pre;
	}

	override string suffix()
	{
		return _allm.front.post;
	}

	override size_t position()
	{
		return offset_ + prefix.length;
	}

	override size_t end_position()
	{
		return position() + str(0).length;
	}

}

class MatchClosed
{
public:
	Match _open_match, _close_match;

	this()
	{
		_open_match = new Match();
		_close_match = new Match();
	}

	this(Match open_match, Match close_match)
	{
		_open_match = open_match;
		_close_match = close_match;
	}

	size_t position()
	{
		return _open_match.position();
	}

	size_t end_position()
	{
		return _close_match.end_position();
	}

	size_t length()
	{
		return _close_match.end_position() - _open_match.position();
	}

	bool found()
	{
		return _open_match.found() && _close_match.found();
	}

	string prefix()
	{
		return _open_match.prefix();
	}

	string suffix()
	{
		return _close_match.suffix();
	}

	string outer()
	{
		return _open_match.str(0) ~ _open_match.suffix()[0 .. _close_match.end_position() - _open_match.end_position()];
	}

	string inner()
	{
		//writeln("close pos : ", _close_match.position(), "    open end : ",
		//		_open_match.end_position());
		return _open_match.suffix()[0 .. _close_match.position() - _open_match.end_position()];
	}
}

class RegexObj
{

	string _pattern;

public:
	this(string pattern)
	{
		_pattern = pattern;
	}

	@property string pattern()
	{
		return _pattern;
	}

	static auto search(string input, string pattern, size_t pos = 0)
	{
		MatchType!(string) m = new MatchType!(string)(pos, pattern);
		auto res = matchAll(pos > 0 ? input[pos .. $] : input, regex(pattern));
		m.setMatchResult(res);
		return m;
	}

	static auto search_first(string input, string pattern, size_t pos = 0)
	{
		MatchType!(string) m = new MatchType!(string)(pos, pattern);
		auto res = matchFirst(pos > 0 ? input[pos .. $] : input, regex(pattern));
		m.setMatchFirst(res);
		return m;
	}

	static auto search_all(string input, size_t pos = 0)
	{
		MatchType!(Delimiter) m = new MatchType!(Delimiter)(pos);
		string[] patterns;
		Delimiter[int] sort_key;
		int i = 1;
		foreach (Delimiter k, string v; regex_map_delimiters)
		{
			patterns ~= v;
			sort_key[i] = k;
			i++;
		}
		auto res = matchAll(pos > 0 ? input[pos .. $] : input, regex(patterns));
		m.setMatchResult(res);
		if (!res.empty)
		{
			auto idx = res.front.whichPattern;
			//writeln("--patterns :",patterns);

			if (idx in sort_key)
			{
				m.set_type(sort_key[idx]);
				m.set_pattern(regex_map_delimiters[m.type]);
				//writeln("--seach first pattern :", m.pattern);
			}
		}

		return m;
	}

	static auto match(T)(string input, string[T] map, size_t pos = 0)
	{
		auto keys = map.keys;
		sort!("a < b")(keys);
		foreach(e;keys)
		{
			auto v =map[e];
			auto res = matchAll(pos > 0 ? input[pos .. $] : input, regex(v));
			if (!res.empty)
			{
				MatchType!(T) mt = new MatchType!(T)(pos, v);
				mt.setMatchResult(res);
				mt.set_type(e);
				//writeln("--match pattern :", v, "   --->type : ", e);
				return mt;
			}
		}
		//writeln("--no match pattern ");
		MatchType!(T) mt = new MatchType!(T)(pos);
		return mt;
	}

	static MatchClosed search_closed_on_level(string input, string regex_statement,
			string regex_level_up, string regex_level_down, string regex_search, Match open_match)
	{

		int level = 0;
		size_t current_position = open_match.end_position();
		auto match_delimiter = search(input, regex_statement, current_position);
		while (match_delimiter.found())
		{
			//writeln("---current_position : ",current_position);
			//writeln("---current  delimiter: ",match_delimiter.str(0));
			current_position = match_delimiter.end_position();
			string inner = match_delimiter.str(1);
			if (search(inner, regex_search).found() && level == 0)
			{
				break;
			}
			if (search(inner, regex_level_up).found())
			{
				level += 1;
			}
			else if (search(inner, regex_level_down).found())
			{
				level -= 1;
			}

			if (level < 0)
			{
				//writeln("-----level<0------", __LINE__);
				return new MatchClosed();
			}
			match_delimiter = search(input, regex_statement, current_position);
		}
		//writeln("-----close match ---end pos---",match_delimiter.end_position(),"---level : ",level);
		return new MatchClosed(open_match, match_delimiter);
	}

	static MatchClosed search_closed(string input, string regex_statement,
			string regex_open, string regex_close, Match open_match)
	{
		return search_closed_on_level(input, regex_statement, regex_open,
				regex_close, regex_close, open_match);
	}
}
