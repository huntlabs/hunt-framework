module hunt.http.exception;

import collie.utils.exception;
import hunt.exception;

mixin ExceptionBuild!("Http","Hunt");

mixin ExceptionBuild!("HttpErro","Http");

mixin ExceptionBuild!("CreateResponse","HttpErro");