import 
  std.stdio,
  std.string,
  hunt.view;

void main()
{
    writeln("Edit source/app.d to start your project.");
 
    //abasic();

    auto tlate = compile_temple!"foo, bar, baz";
    writeln(tlate.toString()); // Prints "foo, bar, baz"

    auto test = compile_temple!q{ Hello, <%=var.name %>};
    auto context = new TempleContext();
    context.name = "dymk";
    writeln(test.toString(context));
    //writeln(test.toString(ctx));
/*    test.render(stdout);
    test.render(function(str) {
        write(str);
    });

    auto dhtml = compile_temple_file!"system/hello.dhtml";
    //auto res = new TempleContext();
    //res.name = "viile";
    writeln(dhtml.toString());*/
}

