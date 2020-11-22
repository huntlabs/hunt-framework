module hunt.framework.jwt.JwtRegisteredClaimNames;

//
// Summary:
//     List of registered claims from different sources http://tools.ietf.org/html/rfc7519#section-4
//     http://openid.net/specs/openid-connect-core-1_0.html#IDToken
struct JwtRegisteredClaimNames {
    enum string Actort = "actort";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-5
    enum string Typ = "typ";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Sub = "sub";
    //
    // Summary:
    //     http://openid.net/specs/openid-connect-frontchannel-1_0.html#OPLogout
    enum string Sid = "sid";
    enum string Prn = "prn";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Nbf = "nbf";
    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest
    enum string Nonce = "nonce";
    enum string NameId = "nameid";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Jti = "jti";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Iss = "iss";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Iat = "iat";
    
    /**
     * End-User's full name in displayable form including all name parts, 
     * possibly including titles and suffixes, ordered according to the End-User's locale and preferences. 
     */
    enum string Name = "name";
    
    enum string Nickname = "nickname";

    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
    enum string GivenName = "given_name";
    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
    enum string FamilyName = "family_name";
    
    enum string MiddleName = "middle_name";

    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
    enum string Gender = "gender";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Exp = "exp";
    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
    enum string Email = "email";
    //
    // Summary:
    //     http://openid.net/specs/openid-connect-core-1_0.html#CodeIDToken
    enum string AtHash = "at_hash";
    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#HybridIDToken
    enum string CHash = "c_hash";
    //
    // Summary:
    //     https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
    enum string Birthdate = "birthdate";
    //
    // Summary:
    //     http://openid.net/specs/openid-connect-core-1_0.html#IDToken
    enum string Azp = "azp";
    //
    // Summary:
    //     http://openid.net/specs/openid-connect-core-1_0.html#IDToken
    enum string AuthTime = "auth_time";
    //
    // Summary:
    //     http://tools.ietf.org/html/rfc7519#section-4
    enum string Aud = "aud";
    //
    // Summary:
    //     http://openid.net/specs/openid-connect-core-1_0.html#IDToken
    enum string Amr = "amr";
    //
    // Summary:
    //     http://openid.net/specs/openid-connect-core-1_0.html#IDToken
    enum string Acr = "acr";
    enum string UniqueName = "unique_name";
    enum string Website = "website";

    enum string PhoneNumber = "phone_number";

    enum string Address = "address";
}
