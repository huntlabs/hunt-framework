import 
  std.stdio,
  std.string,
  hunt.view,
  std.regex,
  std.file;

void main()
{
    writeln("Edit source/app.d to start your project.");

    auto test = compile_temple_file!"test.dhtml";
    auto res  = new TempleContext();
    res.name = "viile";
    writeln(test.toString(res));

    /*
    auto parent = compile_temple!"before {{ yield }} after {{ var.name }}";
    auto child  = compile_temple!"{% int test = 1;  %} between {{ var.name  }}   {!test.dhtml!}";

    auto composed = parent.layout(&child);
    auto res  = new TempleContext();
    res.name = "viile";
    writeln(composed.toString(res));
    //composed.render(stdout);
    */

    //auto r = regex(r"");
    //auto temple = import("test.dhtml");
	//auto res = new TempleContext();
	//res.name = "viile";
	//display("test.dhtml",res);
    //writeln(compile_temple_file!"test.dhtml");
    //auto re = regex(r"\{!.*!\}","mg");
    //writeln(temple);
    //writeln(matchFirst(temple,re));
    
    //auto re = regex(r"(?<=\d)(?=(\d\d\d)+\b)","g");
    //writeln(replaceAll("12000 + 42100 = 54100", re, ","));
}
/*
string display(string temple_string)
{
    auto re = regex(r"\{!.*!\}","mg");
    auto temple = matchFirst(temple_string,re);
    if(!temple)
    {
        return temple_string;
    }
    else
    {
        auto temple_file = temple[0][2 .. $ - 2];
        auto tfile = readText("/data/project/hunt/resources/views/"~temple_file);
        auto new_temple_string = replaceFirst(temple_string,re,tfile);
        if(!matchAll(new_temple_string,re))
        {
            return new_temple_string;
        }
        else
        {
            return display(new_temple_string);
        }
    }
}
*/
