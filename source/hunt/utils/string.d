module hunt.utils.string;

import std.datetime;
import std.conv;
import std.string;
string printDate(DateTime date) {
	return format(
				  "%.3s, %02d %.3s %d %02d:%02d:%02d GMT", // could be UTC too
				  to!string(date.dayOfWeek).capitalize,
				  date.day,
				  to!string(date.month).capitalize,
				  date.year,
				  date.hour,
				  date.minute,
				  date.second);
}