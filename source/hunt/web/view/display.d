module hunt.web.view.display;

import hunt.web.view;

const CompiledTemple layouts_main;
const CompiledTemple hello;

static this() {
        layouts_main = compile_temple_file!"layouts/main.dhtml";
        hello = compile_temple_file!"hello.dhtml";
}
