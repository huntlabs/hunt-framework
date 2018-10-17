module hunt.framework.messaging.exception;

import hunt.lang.exception;

class NestedRuntimeException: Exception
{
    mixin BasicExceptionCtors;
}

class StompConversionException: NestedRuntimeException
{
    mixin BasicExceptionCtors;
}


class InvalidMimeTypeException: IllegalArgumentException
{
    mixin BasicExceptionCtors;
}
