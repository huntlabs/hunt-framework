import 
  std.stdio,
  std.string,
  hunt.view;

void main()
{
    writeln("Edit source/app.d to start your project.");

    /*
    auto test = compile_temple_file!"test.dhtml";
    auto res  = new TempleContext();
    res.name = "viile";
    writeln(test.toString(res));
    */

    auto parent = compile_temple!"before {{ yield }} after {{ var.name }}";
    auto child  = compile_temple!"between {{ var.name  }}";

    auto composed = parent.layout(&child);
    auto res  = new TempleContext();
    res.name = "viile";
    writeln(composed.toString(res));
    //composed.render(stdout);
}
