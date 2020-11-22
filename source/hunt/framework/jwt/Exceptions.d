module hunt.framework.jwt.Exceptions;

import std.exception;

class SignException : Exception {
	this(string s) { super(s); }
}

class VerifyException : Exception {
	this(string s) { super(s); }
}


/**
* thrown when the tokens is expired
*/
class ExpiredException : VerifyException {
    this(string s) {
        super(s);
    }
}

/**
* thrown when the tokens will expire before it becomes valid
* usually when the nbf claim is greater than the exp claim
*/
class ExpiresBeforeValidException : Exception {
    this(string s) {
        super(s);
    }
}