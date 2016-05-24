import std.stdio;
import std.stdlib;
import hunt.web.view;

void show()
{
    const CompiledTemple layouts_main;
    const CompiledTemple hello;

    layouts_main = compile_temple_file!"layouts/main.dhtml";
    hello = compile_temple_file!"hello.dhtml";

    auto context = new TempleContext();
    context.name = "viile";

    layouts_main.layout(&hello).render(function(str) {
            write(str);
    }, content);
}
