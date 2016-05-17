module hunt.view.examples.usage;

import 
  hunt.view,
  std.stdio,
  std.string;

void abasic()
{
    auto tlate = compile_temple!"foo, bar, baz";
    writeln(tlate.toString()); // Prints "foo, bar, baz"
}
