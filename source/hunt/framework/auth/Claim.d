module hunt.framework.auth.Claim;

import std.variant;

/**
 * 
 */
class Claim {

    private string _type;
    private Variant _value;
    
    this(T)(string type, T value) {
        _type = type;
        static if(is(T == Variant)) {
            _value = value;
        } else {
            _value = Variant(value);
        }
    }

    string type() {
        return _type;
    }

    Variant value() {
        return _value;
    }

    override string toString() {
        return _value.toString();
    }
}
