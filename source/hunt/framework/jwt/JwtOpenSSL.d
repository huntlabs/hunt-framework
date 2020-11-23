module hunt.framework.jwt.JwtOpenSSL;

import deimos.openssl.ssl;
import deimos.openssl.pem;
import deimos.openssl.rsa;
import deimos.openssl.hmac;
import deimos.openssl.err;

import hunt.framework.jwt.Exceptions;
import hunt.framework.jwt.JwtAlgorithm;


// extern(C) nothrow void HMAC_CTX_reset(HMAC_CTX * ctx);

EC_KEY* getESKeypair(uint curve_type, string key) {
    EC_GROUP* curve;
    EVP_PKEY* pktmp;
    BIO* bpo;
    EC_POINT* pub;

    if(null == (curve = EC_GROUP_new_by_curve_name(curve_type)))
        throw new Exception("Unsupported curve.");
    scope(exit) EC_GROUP_free(curve);

    bpo = BIO_new_mem_buf(cast(char*)key.ptr, -1);
    if(bpo is null) {
        throw new Exception("Can't load the key.");
    }
    scope(exit) BIO_free(bpo);

    pktmp = PEM_read_bio_PrivateKey(bpo, null, null, null);
    if(pktmp is null) {
        throw new Exception("Can't load the evp_pkey.");
    }
    scope(exit) EVP_PKEY_free(pktmp);

    EC_KEY* eckey;
    eckey = EVP_PKEY_get1_EC_KEY(pktmp);
    if(eckey is null) {
        throw new Exception("Can't convert evp_pkey to EC_KEY.");
    }
    scope(failure) EC_KEY_free(eckey);

    if(1 != EC_KEY_set_group(eckey, curve)) {
        throw new Exception("Can't associate group with the key.");
    }

    const BIGNUM *prv = EC_KEY_get0_private_key(eckey);
    if(null == prv) {
        throw new Exception("Can't get private key.");
    }

    pub = EC_POINT_new(curve);
    if(null == pub) {
        throw new Exception("Can't allocate EC point.");
    }
    scope(exit) EC_POINT_free(pub);

    if (1 != EC_POINT_mul(curve, pub, prv, null, null, null)) {
        throw new Exception("Can't calculate public key.");
    }

    if(1 != EC_KEY_set_public_key(eckey, pub)) {
        throw new Exception("Can't set public key.");
    }

    return eckey;
}


EC_KEY* getESPrivateKey(uint curve_type, string key) {
    EC_GROUP* curve;
    EVP_PKEY* pktmp;
    BIO* bpo;

    if(null == (curve = EC_GROUP_new_by_curve_name(curve_type)))
        throw new Exception("Unsupported curve.");
    scope(exit) EC_GROUP_free(curve);

    bpo = BIO_new_mem_buf(cast(char*)key.ptr, -1);
    if(bpo is null) {
        throw new Exception("Can't load the key.");
    }
    scope(exit) BIO_free(bpo);

    pktmp = PEM_read_bio_PrivateKey(bpo, null, null, null);
    if(pktmp is null) {
        throw new Exception("Can't load the evp_pkey.");
    }
    scope(exit) EVP_PKEY_free(pktmp);

    EC_KEY * eckey;
    eckey = EVP_PKEY_get1_EC_KEY(pktmp);
    if(eckey is null) {
        throw new Exception("Can't convert evp_pkey to EC_KEY.");
    }

    scope(failure) EC_KEY_free(eckey);
    if(1 != EC_KEY_set_group(eckey, curve)) {
        throw new Exception("Can't associate group with the key.");
    }

    return eckey;
}


EC_KEY* getESPublicKey(uint curve_type, string key) {
    EC_GROUP* curve;

    if(null == (curve = EC_GROUP_new_by_curve_name(curve_type)))
        throw new Exception("Unsupported curve.");
    scope(exit) EC_GROUP_free(curve);

    EC_KEY* eckey;

    BIO* bpo = BIO_new_mem_buf(cast(char*)key.ptr, -1);
    if(bpo is null) {
        throw new Exception("Can't load the key.");
    }
    scope(exit) BIO_free(bpo);

    eckey = PEM_read_bio_EC_PUBKEY(bpo, null, null, null);
    scope(failure) EC_KEY_free(eckey);

    if(1 != EC_KEY_set_group(eckey, curve)) {
        throw new Exception("Can't associate group with the key.");
    }

    if(0 == EC_KEY_check_key(eckey))
        throw new Exception("Public key is not valid.");

    return eckey;
}

string sign(string msg, string key, JWTAlgorithm algo = JWTAlgorithm.HS256) {
    ubyte[] sign;

    void sign_hs(const(EVP_MD)* evp, uint signLen) {
        sign = new ubyte[signLen];

        HMAC_CTX ctx;
        scope(exit) HMAC_CTX_reset(&ctx);
        HMAC_CTX_reset(&ctx);
       
        if(0 == HMAC_Init_ex(&ctx, key.ptr, cast(int)key.length, evp, null)) {
            throw new Exception("Can't initialize HMAC context.");
        }
        if(0 == HMAC_Update(&ctx, cast(const(ubyte)*)msg.ptr, cast(ulong)msg.length)) {
            throw new Exception("Can't update HMAC.");
        }
        if(0 == HMAC_Final(&ctx, cast(ubyte*)sign.ptr, &signLen)) {
            throw new Exception("Can't finalize HMAC.");
        }
    }

    void sign_rs(ubyte* hash, int type, uint len, uint signLen) {
        sign = new ubyte[len];

        RSA* rsa_private = RSA_new();
        scope(exit) RSA_free(rsa_private);

        BIO* bpo = BIO_new_mem_buf(cast(char*)key.ptr, -1);
        if(bpo is null)
            throw new Exception("Can't load the key.");
        scope(exit) BIO_free(bpo);

        RSA* rsa = PEM_read_bio_RSAPrivateKey(bpo, &rsa_private, null, null);
        if(rsa is null) {
            throw new Exception("Can't create RSA key.");
        }
        if(0 == RSA_sign(type, hash, signLen, sign.ptr, &signLen, rsa_private)) {
            throw new Exception("Can't sign RSA message digest.");
        }
    }

    void sign_es(uint curve_type, ubyte* hash, int hashLen) {
        EC_KEY* eckey = getESPrivateKey(curve_type, key);
        scope(exit) EC_KEY_free(eckey);

        ECDSA_SIG* sig = ECDSA_do_sign(hash, hashLen, eckey);
        if(sig is null) {
            throw new Exception("Digest sign failed.");
        }
        scope(exit) ECDSA_SIG_free(sig);

        sign = new ubyte[ECDSA_size(eckey)];
        ubyte* c = sign.ptr;
        if(!i2d_ECDSA_SIG(sig, &c)) {
            throw new Exception("Convert sign to DER format failed.");
        }
    }

    switch(algo) {
        case JWTAlgorithm.NONE: {
            break;
        }
        case JWTAlgorithm.HS256: {
            sign_hs(EVP_sha256(), SHA256_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.HS384: {
            sign_hs(EVP_sha384(), SHA384_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.HS512: {
            sign_hs(EVP_sha512(), SHA512_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.RS256: {
            ubyte[] hash = new ubyte[SHA256_DIGEST_LENGTH];
            SHA256(cast(const(ubyte)*)msg.ptr, msg.length, hash.ptr);
            sign_rs(hash.ptr, NID_sha256, 256, SHA256_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.RS384: {
            ubyte[] hash = new ubyte[SHA384_DIGEST_LENGTH];
            SHA384(cast(const(ubyte)*)msg.ptr, msg.length, hash.ptr);
            sign_rs(hash.ptr, NID_sha384, 384, SHA384_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.RS512: {
            ubyte[] hash = new ubyte[SHA512_DIGEST_LENGTH];
            SHA512(cast(const(ubyte)*)msg.ptr, msg.length, hash.ptr);
            sign_rs(hash.ptr, NID_sha512, 512, SHA512_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.ES256: {
            ubyte[] hash = new ubyte[SHA256_DIGEST_LENGTH];
            SHA256(cast(const(ubyte)*)msg.ptr, msg.length, hash.ptr);
            sign_es(NID_secp256k1, hash.ptr, SHA256_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.ES384: {
            ubyte[] hash = new ubyte[SHA384_DIGEST_LENGTH];
            SHA384(cast(const(ubyte)*)msg.ptr, msg.length, hash.ptr);
            sign_es(NID_secp384r1, hash.ptr, SHA384_DIGEST_LENGTH);
            break;
        }
        case JWTAlgorithm.ES512: {
            ubyte[] hash = new ubyte[SHA512_DIGEST_LENGTH];
            SHA512(cast(const(ubyte)*)msg.ptr, msg.length, hash.ptr);
            sign_es(NID_secp521r1, hash.ptr, SHA512_DIGEST_LENGTH);
            break;
        }

        default:
            throw new SignException("Wrong algorithm.");
    }

    return cast(string)sign;
}


bool verifySignature(string signature, string signing_input, string key, JWTAlgorithm algo = JWTAlgorithm.HS256) {

    bool verify_rs(ubyte* hash, int type, uint len, uint signLen) {
        RSA* rsa_public = RSA_new();
        scope(exit) RSA_free(rsa_public);

        BIO* bpo = BIO_new_mem_buf(cast(char*)key.ptr, -1);
        if(bpo is null)
            throw new Exception("Can't load key to the BIO.");
        scope(exit) BIO_free(bpo);

        RSA* rsa = PEM_read_bio_RSA_PUBKEY(bpo, &rsa_public, null, null);
        if(rsa is null) {
            throw new Exception("Can't create RSA key.");
        }

        ubyte[] sign = cast(ubyte[])signature;
        int ret = RSA_verify(type, hash, signLen, sign.ptr, len, rsa_public);
        return ret == 1;
    }

    bool verify_es(uint curve_type, ubyte* hash, int hashLen ) {
        EC_KEY* eckey = getESPublicKey(curve_type, key);
        scope(exit) EC_KEY_free(eckey);

        ubyte* c = cast(ubyte*)signature.ptr;
        ECDSA_SIG* sig = null;
        sig = d2i_ECDSA_SIG(&sig, cast(const (ubyte)**)&c, cast(int) key.length);
        if (sig is null) {
            throw new Exception("Can't decode ECDSA signature.");
        }
        scope(exit) ECDSA_SIG_free(sig);

        int ret =  ECDSA_do_verify(hash, hashLen, sig, eckey);
        return ret == 1;
    }

    switch(algo) {
        case JWTAlgorithm.NONE: {
            return key.length == 0;
        }
        case JWTAlgorithm.HS256:
        case JWTAlgorithm.HS384:
        case JWTAlgorithm.HS512: {
            return signature == sign(signing_input, key, algo);
        }
        case JWTAlgorithm.RS256: {
            ubyte[] hash = new ubyte[SHA256_DIGEST_LENGTH];
            SHA256(cast(const(ubyte)*)signing_input.ptr, signing_input.length, hash.ptr);
            return verify_rs(hash.ptr, NID_sha256, 256, SHA256_DIGEST_LENGTH);
        }
        case JWTAlgorithm.RS384: {
            ubyte[] hash = new ubyte[SHA384_DIGEST_LENGTH];
            SHA384(cast(const(ubyte)*)signing_input.ptr, signing_input.length, hash.ptr);
            return verify_rs(hash.ptr, NID_sha384, 384, SHA384_DIGEST_LENGTH);
        }
        case JWTAlgorithm.RS512: {
            ubyte[] hash = new ubyte[SHA512_DIGEST_LENGTH];
            SHA512(cast(const(ubyte)*)signing_input.ptr, signing_input.length, hash.ptr);
            return verify_rs(hash.ptr, NID_sha512, 512, SHA512_DIGEST_LENGTH);
        }

        case JWTAlgorithm.ES256:{
            ubyte[] hash = new ubyte[SHA256_DIGEST_LENGTH];
            SHA256(cast(const(ubyte)*)signing_input.ptr, signing_input.length, hash.ptr);
            return verify_es(NID_secp256k1, hash.ptr, SHA256_DIGEST_LENGTH );
        }
        case JWTAlgorithm.ES384:{
            ubyte[] hash = new ubyte[SHA384_DIGEST_LENGTH];
            SHA384(cast(const(ubyte)*)signing_input.ptr, signing_input.length, hash.ptr);
            return verify_es(NID_secp384r1, hash.ptr, SHA384_DIGEST_LENGTH );
        }
        case JWTAlgorithm.ES512: {
            ubyte[] hash = new ubyte[SHA512_DIGEST_LENGTH];
            SHA512(cast(const(ubyte)*)signing_input.ptr, signing_input.length, hash.ptr);
            return verify_es(NID_secp521r1, hash.ptr, SHA512_DIGEST_LENGTH );
        }

        default:
            throw new VerifyException("Wrong algorithm.");
    }
}

