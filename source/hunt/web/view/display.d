/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 * template parsing is based on dymk/temple source from https://github.com/dymk/temple
 */
module hunt.web.view.display;

import hunt.web.view;

const CompiledTemple layouts_main;
const CompiledTemple hello;

static this() {
        layouts_main = compile_temple_file!"layouts/main.dhtml";
        hello = compile_temple_file!"hello.dhtml";
}
