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

    auto test = compile_temple!`
        Hello, {%=var.name %}
        {% auto a = 3; %}
        {%= a %}
    `;
    auto context = new TempleContext();
    context.name = "owner";
    writeln(test.toString(context));

    auto dhtml = compile_temple_file!"system/hello.dhtml";
    auto res = new TempleContext();
    res.name = "viile";
    writeln(dhtml.toString(res));

    display!"system/hello.dhtml";

    string name = "iiiiiiii";
    auto arga = [
        "name" : "test",
        "sex" : "man"
    ];
    int[] argb = [1];
    string[] argc = ["ads"];
    
    abc(name,arga);
    //display("system/hello.dhtml",res);
    //ttest(42,12.4,1.5);

    string filename = "system/hello.dhtml";
    auto basic = compile_temple!`
        {% auto t = compile_temple!"########";writeln(t.toString()); %}
        ---  {%= yield %} ---
    `;
    auto parent = compile_temple!"before ---{%= yield %}--- after";
    auto child  = compile_temple!`
        {%= display!"system/hello.dhtml" %}
        {%= display!("system/hello.dhtml",["name":"testdddd","sex":"man"]) %}
    `;

    auto composed = parent.layout(&child);
    auto finout = basic.layout(&composed);
    finout.render(stdout);
}

void abc(T,F)(T va,F[string] vb)
{
    writeln(va,vb);
}
/*
void ttest(T,F)(T vala,F valb,F valc)
{
    writeln(vala,valb+valc);
}

void display(string filename)()
{
    auto temple = compile_temple_file!filename; 
    auto res = new TempleContext();
    res.name = filename;
    writeln(temple.toString(res));
}

void display(string filename,Object res)
{
    writeln(filename);
    writeln(res);
}

void add(T, F)(T a, F b)
{
 return a+b;
}
int a = 1;
int b =2;
int c = add(a, b)

double d = 1;
double e = 2;
double f = add(d, e);
*/
