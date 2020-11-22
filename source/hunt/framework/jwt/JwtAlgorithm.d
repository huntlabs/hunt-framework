module hunt.framework.jwt.JwtAlgorithm;


enum JWTAlgorithm : string {
	NONE  = "none",
	HS256 = "HS256",
	HS384 = "HS384",
	HS512 = "HS512",
	RS256 = "RS256",
	RS384 = "RS384",
	RS512 = "RS512",
	ES256 = "ES256",
	ES384 = "ES384",
	ES512 = "ES512"
}



import std.base64;

alias Base64URLNoPadding = Base64Impl!('-', '_', Base64.NoPadding);


/**
 * Encode a string with URL-safe Base64.
 */
string urlsafeB64Encode(string inp) pure nothrow {
	return Base64URLNoPadding.encode(cast(ubyte[])inp);
}

/**
 * Decode a string with URL-safe Base64.
 */
string urlsafeB64Decode(string inp) pure {
	return cast(string)Base64URLNoPadding.decode(inp);
}
