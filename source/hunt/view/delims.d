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
