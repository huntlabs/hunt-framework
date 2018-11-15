module hunt.framework.messaging.converter.MessageConverterHelper;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.support.GenericMessage;
import hunt.lang.exception;
import hunt.logging;

class MessageConverterHelper {
    static T fromMessage(T)(MessageBase message) {
        T r = T.init; 

        GenericMessage!(byte[]) m;
        if(message.payloadType == typeid(byte[])) {
            m = cast(GenericMessage!(byte[]))message;
        }
        else if(message.payloadType != typeid(T)) {
            warningf("Wrong message type, expected: %s, actual: %s", 
                typeid(T), message.payloadType);
            return r;
        }

        MessageHeaders headers = message.getHeaders;

        static if(is(T == byte[])) {
            return m.getPayload();
        } else static if(is(T == string)) {
            r = cast(string) m.getPayload();
        } else {
            warningf("Can't handle message for type: %s", typeid(T));
        }

        return r;
    }

    // static string getAsString(GenericMessage!(byte[]) message) {
    //     return cast(string) message.getPayload();
    // }
}