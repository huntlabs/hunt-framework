/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 * template parsing is based on dymk/temple source from https://github.com/dymk/temple
 */
module hunt.web.view.delims;

import std.traits, std.typecons;

/// Represents a delimer and the index that it is located at
template DelimPos(D = Delim)
{
    alias DelimPos = Tuple!(size_t, "pos", D, "delim");
}

/// All of the delimer types parsed by Temple
enum Delim
{
    OpenShort,
    OpenShortStr,
    Open,
    OpenStr,
    CloseShort,
    Close,
    CloseStr,
	//OpenInclude,
	//CloseInclude
}

enum Delims = [EnumMembers!Delim];

/// Subset of Delims, only including opening delimers
enum OpenDelim : Delim
{
    OpenShort = Delim.OpenShort,
    Open = Delim.Open,
    OpenShortStr = Delim.OpenShortStr,
    OpenStr = Delim.OpenStr,
//    OpenInclude = Delim.OpenInclude,
}

enum OpenDelims = [EnumMembers!OpenDelim];

/// Subset of Delims, only including close delimers
enum CloseDelim : Delim
{
    CloseShort = Delim.CloseShort,
    Close = Delim.Close,
    CloseStr = Delim.CloseStr,
//    CloseInclude = Delim.CloseInclude,
}

enum CloseDelims = [EnumMembers!CloseDelim];

/// Maps an open delimer to its matching closing delimer
/// Formally, an onto function
enum OpenToClose = [
        OpenDelim.OpenShort : CloseDelim.CloseShort,
		OpenDelim.OpenShortStr : CloseDelim.CloseShort,
        OpenDelim.Open : CloseDelim.Close,
		OpenDelim.OpenStr : CloseDelim.CloseStr,
	//	OpenDelim.OpenInclude : CloseDelim.CloseInclude,
    ];

string toString(in Delim d)
{
    final switch (d) with (Delim)
    {
    case OpenShort:
        return "%";
    case OpenShortStr:
        return "%=";
    case Open:
        return "{%";
    case OpenStr:
        return "{{";
    case CloseShort:
        return "\n";
    case Close:
        return "%}";
    case CloseStr:
        return "}}";
	//case OpenInclude:
	//	return "{!";
	//case CloseInclude:
	//	return "!}";
    }
}

/// Is the delimer a shorthand delimer?
/// e.g., `%=`, or `%`
bool isShort(in Delim d)
{
    switch (d) with (Delim)
    {
    case OpenShortStr:
    case OpenShort:
        return true;
    default:
        return false;
    }
}

unittest
{
    static assert(Delim.OpenShort.isShort() == true);
    static assert(Delim.Close.isShort() == false);
}

/// Is the contents of the delimer evaluated and appended to
/// the template buffer? E.g. the content within `<%= %>` delims
bool isStr(in Delim d)
{
    switch (d) with (Delim)
    {
    case OpenShortStr:
    case OpenStr:
        return true;
    default:
        return false;
    }
}
/*
bool isIncludeStr(in Delim d)
{
	switch (d) with (Delim)
	{
		case OpenInclude:
			return true;
		default:
			return false;
	}
}
*/
unittest
{
    static assert(Delim.OpenShort.isStr() == false);
    static assert(Delim.OpenShortStr.isStr() == true);
}