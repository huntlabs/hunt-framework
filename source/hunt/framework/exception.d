/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.exception;

import hunt.lang.exception;

mixin ExceptionBuild!("Hunt","");

mixin ExceptionBuild!("Http","Hunt");

mixin ExceptionBuild!("HttpErro","Http");

mixin ExceptionBuild!("CreateResponse","HttpErro");

