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

module hunt.http.nullbuffer;

import collie.buffer;

final class NullBuffer : Buffer
{
	override @property bool eof() const {return true;}

	override size_t read(size_t size, scope void delegate(in ubyte[]) cback){ return 0;}
	override size_t write(in ubyte[] data) { return 0;}

	override void rest(size_t size = 0){}
	override @property size_t length() const{ return 0;}
	
	override size_t readLine(scope void delegate(in ubyte[]) cback){return 0;} //回调模式，数据不copy
	
	override size_t readAll(scope void delegate(in ubyte[]) cback){return 0;}
	
	override size_t readUtil(in ubyte[] data, scope void delegate(in ubyte[]) cback){return 0;}
	
	override size_t readPos(){return 0;}
}

@property defaultBuffer(){return _default;}

shared static this(){
	_default =  new NullBuffer;
}

private:
__gshared NullBuffer _default;