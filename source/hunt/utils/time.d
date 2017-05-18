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

module hunt.utils.time;

import std.datetime;
import core.stdc.time;


int getCurrUnixStramp()
{
	SysTime currentTime = cast(SysTime)Clock.currTime();
	time_t time = currentTime.toUnixTime;
	return cast(int)(time);
}
