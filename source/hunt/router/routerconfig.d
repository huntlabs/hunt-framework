module hunt.router.routerconfig;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

struct RouterContext
{
    string method;
    string path;
    string hander;
    string[] middleWareBefore;
    string[] middleWareAfter;
}

class RouterConfig
{
    this(string file_path, string prefix)
    in
    {
	assert(exists(file_path), "Error file path!");
    }
    body
    {
	_filePath = file_path;
	_prefix = prefix;
    }
    
    ~this()
    {
	
    }
    RouterContext[] do_parse()
    {
	return this._routerContext;
    }
    void set_file_path(string file_path)
    {
	this._file_path = file_path;
    }
    void set_prefix(string prefix)
    {
	this._prefix = prefix;
    }
protected: 
    RouterContext[] _routerContext;
    string _prefix;
    string _file_path;//文件路径
}

class ConfigParse : RouterConfig
{
    this(string file_path, string prefix=string.init)
    {
	super(file_path, prefix);
    }
public:
    override @property RouterContext[] do_parse() 
    {
	string full_method = "OPTIONS,GET,HEAD,POST,PUT,DELETE,TRACE,CONNECT";
	string[] output_lines;
	size_t file_size = cast(size_t) getSize(cast(char[]) _file_path);
	assert(file_size,"Empty file!");
	string read_buff;
	try{
	    read_buff = cast(string) read(cast(char[]) _file_path, file_size);
	}catch(Exception ex){
	    //assert("Read router config file error!);
	    throw ex;
	}
	string[] line_buffers = splitLines(read_buff);
	foreach(line; line_buffers)
	{
	    if(line != string.init && (line.indexOf('#')<0))
	    {
		string[] tmp_splites = splite_by_space(line);
		RouterContext tmp_route;
		if(tmp_splites[0] == "*")
		    tmp_route.method = full_method;
		else
		    tmp_route.method = toUpper(tmp_splites[0]);
		tmp_route.path = tmp_splites[1];
		tmp_route.hander = parse_to_full_controll(tmp_splites[2]);
		if(tmp_splites.length == 4)
		    parse_middleware(tmp_splites[3], tmp_route.middleWareBefore, tmp_route.middleWareAfter);
		_routerContext ~= tmp_route;
	    }
	}
	return _routerContext;
    }
    void setControllerPrefix(string controller_prefix)
    {
	_controller_prefix = controller_prefix;
    }
    void set_before_flag(string before_flag)
    {
	_before_flag = before_flag;
    }
    void set_after_flag(string after_flag)
    {
	_after_flag = after_flag;
    }
private:
    string parse_to_full_controll(string in_buff)
    {
	string[] sprit_arr = split(in_buff, '/');
	assert(sprit_arr.length > 1, "whitout /");
	string output;
	if(_prefix)
	{
	    assert(sprit_arr.length == 4, "Wrong controller config!");
	    output ~= sprit_arr[0]~"."~sprit_arr[1]~"."~to!string(sprit_arr[2].asCapitalized)~_controller_prefix~"."~sprit_arr[3];
	}
	else
	{
	    assert(sprit_arr.length == 3, "Wrong controller config!");
	    output ~= "application"~"."~sprit_arr[0]~"."~to!string(sprit_arr[1].asCapitalized)~_controller_prefix~"."~sprit_arr[2];
	}

	return output;
    }
    string[] splite_by_space(string in_buff)
    {
	auto r = regex(r"\S+");

	auto get_splite_items = matchAll(in_buff, r);
	assert(get_splite_items, "Could not splite by space!");
	string output[];
	foreach(s; get_splite_items)
	    output ~= cast(string) s.hit;
	return output;
    }
    void parse_middleware(string to_parse, out string[] before_middleware, out string[] after_middleware)
    {
	int before_pos, after_pos, semicolon_pos;
	before_pos = to_parse.indexOf(_before_flag);
	after_pos = to_parse.indexOf(_after_flag);
	semicolon_pos = to_parse.indexOf(";");
	assert(before_pos <= after_pos, "after position and before position worry");
	//assert(before_pos 
	writeln("to_parse: ", to_parse, " before_pos: ",before_pos);
	if(before_pos<0)
	    before_pos = to_parse.length-1;
	else
	    before_pos += _before_flag.length;
	if(after_pos<0)
	    after_pos = to_parse.length-1;
	else
	    after_pos += _after_flag.length;
	if(semicolon_pos<0)
	    semicolon_pos = to_parse.length-1;
	if(before_pos < semicolon_pos)
	    before_middleware = split(to_parse[before_pos..semicolon_pos], ',');
	after_middleware = split(to_parse[after_pos..$], ',');
	writeln("before_middleware: ", before_middleware, " after_middleware: ", after_middleware);
    }
    
private:
    string _controller_prefix="Controller";
    string _before_flag= "before:";
    string _after_flag= "after:";
}

unittest
{
    ConfigParse new_parse = new ConfigParse("router.conf");
    //new_parse.set_file_path("router.conf");
    RouterContext[] test_router_context = new_parse.do_parse();
    foreach(item; test_router_context)
    {
	writeln("method: ",item.method, " path: ", item.path, " hander: ", item.hander, " middleWareAfter: ", item.middleWareAfter, " middleWareBefore: ", item.middleWareBefore);
    }
}
