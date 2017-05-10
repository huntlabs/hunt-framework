module hunt.utils.time;

import std.datetime;
import core.stdc.time;


int getCurrUnixStramp()
{
	SysTime currentTime = cast(SysTime)Clock.currTime();
	time_t time = currentTime.toUnixTime;
	return cast(int)(time);
}
