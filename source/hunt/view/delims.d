/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.view.delims;

import hunt.view;

enum Delim
{
	Open,
	OpenStr,
	Close,
	CloseStr,
}

string toString(in Delim d)
{
	final switch(d) with(Delim)
	{
		case Open:          return "{%";
		case OpenStr:       return "{{";
		case Close:         return "%}";
		case CloseStr:      return "}}";
	}
}
