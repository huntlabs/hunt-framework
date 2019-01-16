﻿/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.nt.framework.exception;

import hunt.Exceptions;

mixin ExceptionBuild!("Hunt","");

mixin ExceptionBuild!("Http","Hunt");

mixin ExceptionBuild!("HttpErro","Http");

mixin ExceptionBuild!("CreateResponse","HttpErro");

