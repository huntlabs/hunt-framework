import std.stdio;
import std.json;

import hunt.templates;

void main()
{
	JSONValue data;
	data["name"] = "Cree";
	data["alias"] = "Cree";
	data["city"] = "Christchurch";
	data["age"] = 3;
	data["age1"] = 28;
	data["addrs"] = ["ShangHai", "BeiJing"];
	data["is_happy"] = false;
	data["allow"] = false;
	data["users"] = ["name" : "jeck", "age" : "18"];
	JSONValue user1;
	user1["name"] = "cree";
	user1["age"] = 2;
	user1["hobby"] = ["eat", "drink"];
	JSONValue user2;
	user2["name"] = "jeck";
	user2["age"] = 28;
	user2["hobby"] = ["sing", "football"];
	JSONValue[] userinfo;
	userinfo ~= user1;
	userinfo ~= user2;
	JSONValue data2;
	data2["userinfo"] = userinfo;

	string input;
	writeln("------------------IF--------------------------");
	input="{% if is_happy %}happy{% else %}unhappy{% endif %}";
	writeln("result : ",Env().render(input, data));

	writeln("------------------FOR-------------------------");
	input = "{% for addr in addrs %}{{addr}} {% endfor %}";
	writeln("result : ",Env().render(input, data));

	writeln("------------------FOR2-------------------------");
	input = "<ul>{% for addr in addrs %}<li><a href=\"{{ addr }}\">{{ addr }}</a></li>{% endfor %}</ul>";
	writeln("result : ",Env().render(input, data));

	writeln("------------------MAP-------------------------");
	input = "{% for k,v in users %}{{ k }} -- {{ v }}  {% endfor %}";
	writeln("result : ",Env().render(input, data));

	writeln("------------------FUNC upper------------------");
	input = "{{ upper(city) }}";
	writeln("result : ",Env().render(input, data));

	writeln("----------------FUNC lower--------------------");
	input = "{{ lower(city) }}";
	writeln("result : ",Env().render(input, data));

	writeln("-------------FUNC compare operator------------");
	input = "{% if length(addrs)>=4 %}true{% else %}false{% endif %}";
	writeln("result : ",Env().render(input, data));

	writeln("-------------FUNC compare operator (string)------------");
	input = "{% if name != \"Peter\" %}true{% else %}false{% endif %}";
	writeln("result : ",Env().render(input, data));

	writeln("---------Render file with `include`-----------");
	writeln("result : ", Env().render_file("index.txt", data));

	writeln("---------------Render file--------------------");
	writeln("result : ", Env().render_file("main.txt", data));

	writeln("---------Render file with `include` & save to file-----------");
	Env().write("index.txt", data,"index.html");


	writeln("------------------Deep for-------------------------");
	input = "{% for user in userinfo %}{{user.hobby.1}} {% endfor %}";
	writeln("result : ",Env().render(input, data2));

	writeln("------------------Deep for 2-------------------------");
	input = "{{userinfo.1.name}}";
	writeln("result : ",Env().render(input, data2));


	writeln("-------------FUNC  operator------------");
	input = "{{ 'a' <= '1' }} ~ {{ age >= age1 }} ~ {{ 2 < 1 }} ~ {{ 4 > 3 }} ~ {{ '4' > 3 }}";
	writeln("result : ",Env().render(input, data));

	writeln("-------------Array value------------");
	input = "{{ addrs.0 }} or {{ users.name }}";
	writeln("result : ",Env().render(input, data));

	 writeln("-------------FUNC length------------");
	 input = "{{ length(name) }} or {{ length(users) }}";
	 writeln("result : ",Env().render(input, data));

	//Util.debug_ast(Env().parse(input).parsed_node);

	JSONValue d;
	d["appname"] = "Vitis";
	d["title"] = "this is test .";
	d["content"] = "Vitis is IM .";
	d["platform"] = "Android";
	d["pushscope"] = "IOS";
	d["type"] = "online";
	d["count"] = 100;
	d["time"] = "Fri Apr 13 17:36:13 CST 2018";
	d["savetotime"] = "Fri Apr 13 17:36:13 CST 2018";
	d["msgid"] = 1000;
	d["userinfo"] = userinfo;

	writeln("---------Render file  & save to file-----------");
	Env().write("detail.txt", d,"detail.html");
}
