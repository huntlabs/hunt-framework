module hunt.router.utils;

import std.stdio;
import std.string;
import std.regex;

enum regex_char= r"[{|*+?().^$/\";
string[string] parseKV(string defaults)
{
    if(defaults is null || defaults.length < 3)
    {
	return null;
    }
    string[string] _d;
    foreach(string kv; defaults[1 .. $-1 ].split(','))
    {
	auto pos = kv.indexOf(':');
	if(pos == -1)
	{
	    continue;
	}
	_d[kv[0 .. pos].strip] = kv[pos+1 .. $].strip;
    }
    return _d;
}

string computeRegexp(ref string[] token, size_t index, size_t firstOptional, ref string[][] tokens)
{
    if ("text" == token[0]) {
	// Text tokens
	return pregQuote(token[1]);
    } else {
	// Variable tokens
	if (0 == index && 0 == firstOptional) {
	    // When the only token is an optional variable token, the separator is required
	    return format("%s(?P<%s>%s)?", pregQuote(token[1]), token[3], token[2]);
	} else {
	    auto regexp = format("%s(?P<%s>%s)", pregQuote(token[1]), token[3], token[2]);
	    if (index >= firstOptional) {
		regexp = "(?:" ~regexp;
		if (tokens.length - 1 == index) {
		    // Close the optional subpatterns
		    import std.range:repeat, take;
		    regexp ~= ")?".repeat().take(tokens.length - firstOptional - (0 == firstOptional ? 1 : 0)).join();
		}
	    }
	    return regexp;
	}
    }
}

string pregQuote(string str)
{
    immutable(char)[] tmp ;
    foreach(ref c; str)
    {
	if(regex_char.indexOf(c) != -1)
	{
	    tmp~='\\';
	}
	tmp ~= c;
    }
    return tmp;
}

/// 构造正则表达式，类似上个版本的，把配置里的单独的表达式，构建成一个
string buildRegex(string reglist)

    auto reg = regex(r"\{\w+\}","g");

    size_t pos = 0;
    string[][] tokens;
    string[] variables;


    foreach(mc; matchAll(reglist, reg))
    {
	writeln("mc: ", mc);
	string varName = mc.hit[1..$-1]; 
	size_t idMc = reglist.indexOf(mc.hit);
	string precedingText = reglist[pos..idMc];
	pos = idMc + mc.hit.length;

	string precedingChar = precedingText.length > 0 ? precedingText[$-1..$] : "";
	bool isSeparator = precedingChar.length > 0 && "/".indexOf(precedingChar) != -1;

	writeln("varName: ", varName, " precedingText: ", precedingText, " precedingChar: ", precedingChar);
	assert(std.string.isNumeric(varName), format("Variable name %s cannot be numeric in route reglist %s. Please use a different name.", varName, reglist));
	if(isSeparator && precedingText.length > 1)
	{
	    tokens ~= ["text", precedingText[0 .. $-1]];
	}
	else if(!isSeparator && precedingText.length > 0)
	{
	    tokens ~= ["text", precedingText];
	}
	////有问题
	auto regexp = parseKV(varName);
	if(regexp is null)
	{
	    auto followingreglist = reglist[pos .. $];
	    string nextSeparator;
	    if(followingreglist.length == 0)
		nextSeparator = string.init;
	    string tmp_str;
	    tmp_str = replaceAll(followingreglist, reg, "");
	    nextSeparator = (tmp_str.length > 0 && "/".indexOf(tmp_str[0]) != -1) ? tmp_str[0 .. 0] : "";

	    regexp = format("[^%s%s]+",
		    r"\/",
		    "/" != nextSeparator && nextSeparator.length > 0   ? (regex_char.indexOf(nextSeparator) != -1 ? r"\\" ~ nextSeparator : nextSeparator) : ""
		    );
	}
	tokens ~= ["variable", isSeparator ? precedingChar : "", regexp, varName];
	variables ~= varName;
    }
    if(pos < reglist.length)
    {
	tokens ~= ["text", reglist[pos .. $]];
    }
    size_t firstOptional = size_t.max;
    writeln("tokens: ",tokens);
    foreach_reverse(i, ref token; tokens)
    {
	if(token[0] == "variable" )//&& route.hasDefault(token[3]))
	{
	    firstOptional = i;
	}
	else
	{
	    break;
	}
    }
    auto regexp = "";
    foreach(i, ref token; tokens)
    {
	regexp ~= computeRegexp(token, i, firstOptional,  tokens);
    }
    writeln("variables:",variables);
    writeln("tokens:",tokens);
    writeln("regexp:",regexp);
    ///staticPrefix regex tokens variables
    /*return TCompilereglistReturn( 
      "text" == tokens[0][0] ? tokens[0][1] : "",
      "^" ~regexp ~ "$",
      tokens,
      variables
      );	
     */
    return string.init;
}
void main()
{
    string reglist = "{d1:[0-9a-z]{1}}/{d2:[0-9a-z]{2}}/{imagename:\\w+\\.\\w+}";
    writeln("reglist: ", reglist);
    writeln("std.string.isNumeric(\"1\") = ", std.string.isNumeric("1"));
    buildRegex(reglist);
}
/// 判断URL中是否是正则表达式的 (是否有{字符)
bool isHaveRegex(string path)
{
    if(path.indexOf('{') != -1 && path.indexOf('}') != -1)
	return true;
    return false;
}

/// file
/// 取出来地一个path： 例如： /file/ddd/f ; reurn = file,  lpath= /ddd/f;
string getFristPath(string fpath,out string lpath)
{
    size_t sprit_pos;
    bool sprit_in_header;
    if(fpath[0] == '/')
    {
	sprit_pos = fpath[1..$].indexOf('/');
	sprit_in_header = true;
    }
    else
	sprit_pos = fpath.indexOf('/');
    if(sprit_pos == -1)
    {
	lpath = string.init;
	return fpath;
    }
    lpath = fpath[sprit_pos..$];
    if(sprit_in_header)
	return fpath[1..sprit_pos];

    return fpath[0..sprit_pos];
}
