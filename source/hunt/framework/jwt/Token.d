module hunt.framework.jwt.Token;

import hunt.framework.jwt.Exceptions;
import hunt.framework.jwt.JwtAlgorithm;
import hunt.framework.jwt.JwtOpenSSL;

import hunt.framework.jwt.Jwt;
import hunt.logging.ConsoleLogger;


import std.conv;
import std.json;
import std.string;

class Component {
    abstract @property string json();

    @property string base64() {
        string data = this.json();
        return urlsafeB64Encode(data);
    }
}

class Header : Component {

public:
    JWTAlgorithm alg;
    string typ;

    this(in JWTAlgorithm alg, in string typ) {
        this.alg = alg;
        this.typ = typ;
    }

    this(in JSONValue headers) {
        try {
            this.alg = to!(JWTAlgorithm)(toUpper(headers["alg"].str()));

        } catch (Exception e) {
            throw new Exception(alg ~ " algorithm is not supported!");

        }

        this.typ = headers["typ"].str();

    }

    @property override string json() {
        JSONValue headers = ["alg": cast(string)this.alg, "typ": this.typ];

        return headers.toString();

    }
}

import std.datetime;

/**
* represents the claims component of a JWT
*/
class Claims : Component {
private:
    JSONValue data;

    this(in JSONValue claims) {
        this.data = claims;

    }

public:

    this() {
        this.data = JSONValue(["iat": JSONValue(Clock.currTime.toUnixTime())]);

    }

    void set(T)(string name, T data) {
        static if(is(T == JSONValue)) {
            this.data.object[name] = data;
        } else {
            this.data.object[name] = JSONValue(data);
        }
    }

    /**
    * Params:
    *       name = the name of the claim
    * Returns: returns a string representation of the claim if it exists and is a string or an empty string if doesn't exist or is not a string
    */
    string get(string name) {
        try {
            return this.data[name].str();

        } catch (JSONException e) {
            return string.init;

        }

    }

    /**
    * Params:
    *       name = the name of the claim
    * Returns: an array of JSONValue
    */
    JSONValue[] getArray(string name) {
        try {
            return this.data[name].array();

        } catch (JSONException e) {
            return JSONValue.Store.array.init;

        }

    }


    /**
    * Params:
    *       name = the name of the claim
    * Returns: a JSONValue
    */
    JSONValue[string] getObject(string name) {
        try {
            return this.data[name].object();

        } catch (JSONException e) {
            return JSONValue.Store.object.init;

        }

    }

    /**
    * Params:
    *       name = the name of the claim
    * Returns: returns a long representation of the claim if it exists and is an
    *          integer or the initial value for long if doesn't exist or is not an integer
    */
    long getInt(string name) {
        try {
            return this.data[name].integer();

        } catch (JSONException e) {
            return long.init;

        }

    }

    /**
    * Params:
    *       name = the name of the claim
    * Returns: returns a double representation of the claim if it exists and is a
    *          double or the initial value for double if doesn't exist or is not a double
    */
    double getDouble(string name) {
        try {
            return this.data[name].floating();

        } catch (JSONException e) {
            return double.init;

        }

    }

    /**
    * Params:
    *       name = the name of the claim
    * Returns: returns a boolean representation of the claim if it exists and is a
    *          boolean or the initial value for bool if doesn't exist or is not a boolean
    */
    bool getBool(string name) {
        try {
            return this.data[name].type == JSONType.true_;

        } catch (JSONException e) {
            return bool.init;

        }

    }

    /**
    * Params:
    *       name = the name of the claim
    * Returns: returns a boolean value if the claim exists and is null or
    *          the initial value for bool it it doesn't exist or is not null
    */
    bool isNull(string name) {
        try {
            return this.data[name].isNull();

        } catch (JSONException) {
            return bool.init;

        }

    }

    @property void iss(string s) {
        this.data.object["iss"] = s;
    }


    @property string iss() {
        try {
            return this.data["iss"].str();

        } catch (JSONException e) {
            return "";

        }

    }

    @property void sub(string s) {
        this.data.object["sub"] = s;
    }

    @property string sub() {
        try {
            return this.data["sub"].str();

        } catch (JSONException e) {
            return "";

        }

    }

    @property void aud(string s) {
        this.data.object["aud"] = s;
    }

    @property string aud() {
        try {
            return this.data["aud"].str();

        } catch (JSONException e) {
            return "";

        }

    }

    @property void exp(long n) {
        this.data.object["exp"] = n;
    }

    @property long exp() {
        try {
            return this.data["exp"].integer;

        } catch (JSONException) {
            return 0;

        }

    }

    @property void nbf(long n) {
        this.data.object["nbf"] = n;
    }

    @property long nbf() {
        try {
            return this.data["nbf"].integer;

        } catch (JSONException) {
            return 0;

        }

    }

    @property void iat(long n) {
        this.data.object["iat"] = n;
    }

    @property long iat() {
        try {
            return this.data["iat"].integer;

        } catch (JSONException) {
            return 0;

        }

    }

    @property void jit(string s) {
        this.data.object["jit"] = s;
    }

    @property string jit() {
        try {
            return this.data["jit"].str();

        } catch(JSONException e) {
            return "";

        }

    }

    /**
    * gives json encoded claims
    * Returns: json encoded claims
    */
    @property override string json() {
        return this.data.toString();

    }
}

/**
* represents a token
*/
class Token {

private:
    Claims _claims;
    Header _header;

    this(Claims claims, Header header) {
        this._claims = claims;
        this._header = header;
    }

    @property string data() {
        return this.header.base64 ~ "." ~ this.claims.base64;
    }


public:

    this(in JWTAlgorithm alg, in string typ = "JWT") {
        this._claims = new Claims();

        this._header = new Header(alg, typ);

    }

    @property Claims claims() {
        return this._claims;
    }

    @property Header header() {
        return this._header;
    }

    /**
    * used to get the signature of the token
    * Parmas:
    *       secret = the secret key used to sign the token
    * Returns: the signature of the token
    */
    string signature(string secret) {
        return Base64URLNoPadding.encode(cast(ubyte[])sign(this.data, secret, this.header.alg));

    }

    /**
    * encodes the token
    * Params:
    *       secret = the secret key used to sign the token
    *Returns: base64 representation of the token including signature
    */
    string encode(string secret) {
        if ((this.claims.exp != ulong.init && this.claims.iat != ulong.init) && this.claims.exp < this.claims.iat) {
            throw new ExpiredException("Token has already expired");
        }

        if ((this.claims.exp != ulong.init && this.claims.nbf != ulong.init) && this.claims.exp < this.claims.nbf) {
            throw new ExpiresBeforeValidException("Token will expire before it becomes valid");
        }

        string token = this.data ~ "." ~ this.signature(secret);

        version(HUNT_AUTH_DEBUG) {
            tracef("secret: %s, token: %s", secret, token);
        }

        return token;

    }
    ///
    unittest {
        Token token = new Token(JWTAlgorithm.HS512);

        long now = Clock.currTime.toUnixTime();

        string secret = "super_secret";

        token.claims.exp = now - 3600;

        assertThrown!ExpiredException(token.encode(secret));

        token.claims.exp = now + 3600;

        token.claims.nbf = now + 7200;

        assertThrown!ExpiresBeforeValidException(token.encode(secret));

    }

    /**
    * overload of the encode(string secret) function to simplify encoding of token without algorithm none
    * Returns: base64 representation of the token
    */
    string encode() {
        assert(this.header.alg == JWTAlgorithm.NONE);
        return this.encode("");
    }
}


Token decodeAsToken(string token, string delegate(ref JSONValue jose) lazyKey) {
	import std.algorithm : count;
	import std.conv : to;
	import std.uni : toUpper;

    version(HUNT_AUTH_DEBUG) {
        tracef("token: %s", token);
    }

	if(count(token, ".") != 2)
		throw new VerifyException("Token is incorrect.");

	string[] tokenParts = split(token, ".");

	JSONValue header;
	try {
		header = parseJSON(urlsafeB64Decode(tokenParts[0]));
	} catch(Exception e) {
		throw new VerifyException("Header is incorrect.");
	}

	JWTAlgorithm alg;
	try {
		// toUpper for none
		alg = to!(JWTAlgorithm)(toUpper(header["alg"].str()));
	} catch(Exception e) {
		throw new VerifyException("Algorithm is incorrect.");
	}

	if (auto typ = ("typ" in header)) {
		string typ_str = typ.str();
		if(typ_str && typ_str != "JWT")
			throw new VerifyException("Type is incorrect.");
	}

	const key = lazyKey(header);
	if(!key.empty() && !verifySignature(urlsafeB64Decode(tokenParts[2]), tokenParts[0]~"."~tokenParts[1], key, alg))
		throw new VerifyException("Signature is incorrect.");

	JSONValue payload;

	try {
		payload = parseJSON(urlsafeB64Decode(tokenParts[1]));
	} catch(JSONException e) {
		// Code coverage has to miss this line because the signature test above throws before this does
		throw new VerifyException("Payload JSON is incorrect.");
	}

	
    Header h = new Header(header);
	Claims claims = new Claims(payload);

	return new Token(claims, h);
}

Token decodeAsToken(string encodedToken, string key="") {
    return decodeAsToken(encodedToken, (ref _) => key);	
}


bool verify(string token, string key) {
	import std.algorithm : count;
	import std.conv : to;
	import std.uni : toUpper;

	if(count(token, ".") != 2)
		throw new VerifyException("Token is incorrect.");

	string[] tokenParts = split(token, ".");

	string decHeader = urlsafeB64Decode(tokenParts[0]);
	JSONValue header = parseJSON(decHeader);

	JWTAlgorithm alg;
	try {
		// toUpper for none
		alg = to!(JWTAlgorithm)(toUpper(header["alg"].str()));
	} catch(Exception e) {
		throw new VerifyException("Algorithm is incorrect.");
	}

	if (auto typ = ("typ" in header)) {
		string typ_str = typ.str();
		if(typ_str && typ_str != "JWT")
			throw new VerifyException("Type is incorrect.");
	}

	return verifySignature(urlsafeB64Decode(tokenParts[2]), tokenParts[0]~"."~tokenParts[1], key, alg);
}





// import std.conv;
// import std.json;
// import std.format;
    
// // HS512
// void testHS512() {
//     scope(failure) {
//         warning("failed");
//     }

//     scope(success) {
//         info("passed");
//     }

//     string hs_secret = "secret";
//     enum FinalToken = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MDYwMzI4MjQsImxhbmd1YWdlIjoiRCJ9.nIWh2aWLdjA64NWm5P1RO5vG66DKGg8nXAfJ7js3qEV1CoX-BNvXFKvhPJvNby7_ZQTrqHLpCNBWEdtrshxYFQ";
//     long iat = 1606032824;
//     JSONValue payload = parseJSON(`{"iat":1606032824,"language":"D"}`);

//     string hs512Token = encode(payload, hs_secret, JWTAlgorithm.HS512);
//     assert(hs512Token == FinalToken);
//     assert(verify(hs512Token, hs_secret));    
    
//     warning(hs512Token);

//     Token token = new Token(JWTAlgorithm.HS512);
//     token.claims.set("language", "D");
//     token.claims.iat = iat;
//     string hs512Token2 = token.encode(hs_secret);
//     warning(hs512Token2);
//     assert(hs512Token == hs512Token2);

//     //

//     token = decodeAsToken(FinalToken, hs_secret);
//     string language = token.claims.get("language");
//     assert(language == "D");
// }


//     // ES256
// void testES256() {

//     scope(failure) {
//         warning("failed");
//     }

//     scope(success) {
//         info("passed");
//     }

//     string es256_public = q"EOS
// -----BEGIN PUBLIC KEY-----
// MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEMuSnsWbiIPyfFAIAvlbliPOUnQlibb67
// yE6JUqXVaevb8ZorK2HfxfFg9pGVhg3SGuBCbHcJ84WKOX3GSMEwcA==
// -----END PUBLIC KEY-----
// EOS";


//     string es256_private = q"EOS
// -----BEGIN EC PRIVATE KEY-----
// MHQCAQEEIB8cQPtLEF5hOJsom5oVU5dMpgDUR2QYuJTXdtvxezQloAcGBSuBBAAK
// oUQDQgAEMuSnsWbiIPyfFAIAvlbliPOUnQlibb67yE6JUqXVaevb8ZorK2HfxfFg
// 9pGVhg3SGuBCbHcJ84WKOX3GSMEwcA==
// -----END EC PRIVATE KEY-----
// EOS";

//     long iat = 1606032824;
//     JSONValue payload = parseJSON(format(`{"iat":%d,"language":"D"}`, iat));

//     string es256Token = encode(payload, es256_private, JWTAlgorithm.ES256);
//     warning(es256Token);
//     // assert(es256Token == Es256FinalToken);
//     assert(verify(es256Token, es256_public)); 

    
//     string es256Token1 = encode(payload, es256_private, JWTAlgorithm.ES256);
//     trace(es256Token1);

//     assert(es256Token != es256Token1);
    
//     Token token = new Token(JWTAlgorithm.ES256);
//     token.claims.set("language", "D");
//     token.claims.iat = iat;
//     string es256Token2 = token.encode(es256_private);
//     warning(es256Token2);
//     assert(verify(es256Token2, es256_public)); 


//     // 
//     token = decodeAsToken(es256Token2, es256_public);

//     string language = token.claims.get("language");
//     assert(language == "D");        
// }
