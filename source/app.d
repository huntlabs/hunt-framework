import 
  std.stdio,
  std.string,
  hunt.view;

void main()
{
	writeln("Edit source/app.d to start your project.");
    auto tlate = compile_temple!"foo, bar, baz";
    writeln(tlate.toString()); // Prints "foo, bar, baz"

    auto dhtml = compile_temple_file!"system/hello.dhtml";
    auto context = new TempleContext();
    context.hour = 5;
    dhtml.render(stdout);
}
