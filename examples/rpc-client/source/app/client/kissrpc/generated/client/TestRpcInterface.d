module kissrpc.generated.TestRpcInterface;

import kissrpc.generated.TestRpcMessage;
import kissrpc.generated.TestRpcService;

import kissrpc.RpcRequest;
import kissrpc.RpcClientImpl;
import kissrpc.RpcClient;
import kissrpc.RpcResponse;
import kissrpc.Unit;
import flatbuffers;
import kissrpc.generated.message.TestRpc;

abstract class RpcTestInterface{ 

	this(RpcClient rpClient){ 
		rpImpl = new RpcClientImpl!(RpcTestService)(rpClient); 
	}

	UserInfo getNameInterface(const UserInfo userInfo, const RPC_PACKAGE_COMPRESS_TYPE compressType, const int secondsTimeOut, const size_t funcId = 2791659981){

		auto builder = new FlatBufferBuilder(512);

		//input flatbuffer code for UserInfoFB class




				auto userInfoPos = UserInfoFB.createUserInfoFB(builder, userInfo.i, builder.createString(userInfo.name), );


		builder.finish(userInfoPos);

		auto req = new RpcRequest(compressType, secondsTimeOut);

		req.push(builder.sizedByteArray);

		RpcResponse resp = rpImpl.syncCall(req, RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, funcId);

		if(resp.getStatus == RESPONSE_STATUS.RS_OK){

			ubyte[] flatBufBytes;
			resp.pop(flatBufBytes);

			auto ret_UserInfoFB = UserInfoFB.getRootAsUserInfoFB(new ByteBuffer(flatBufBytes));
			UserInfo ret_UserInfo;

			//input flatbuffer code for UserInfoFB class




				ret_UserInfo.i = ret_UserInfoFB.i;
		ret_UserInfo.name = ret_UserInfoFB.name;


			return ret_UserInfo;
		}else{
			throw new Exception("rpc sync call error, function:" ~ RpcBindFunctionMap[funcId]);
		}
	}


	alias RpcgetNameCallback = void delegate(UserInfo);

	void getNameInterface(const UserInfo userInfo, RpcgetNameCallback rpcCallback, const RPC_PACKAGE_COMPRESS_TYPE compressType, const int secondsTimeOut, const size_t funcId = 2791659981){

		auto builder = new FlatBufferBuilder(512);
		//input flatbuffer code for UserInfoFB class




				auto userInfoPos = UserInfoFB.createUserInfoFB(builder, userInfo.i, builder.createString(userInfo.name), );


		builder.finish(userInfoPos);
		auto req = new RpcRequest(compressType, secondsTimeOut);

		req.push(builder.sizedByteArray);

		rpImpl.asyncCall(req, delegate(RpcResponse resp){

			if(resp.getStatus == RESPONSE_STATUS.RS_OK){

				ubyte[] flatBufBytes;
				UserInfo ret_UserInfo;

				resp.pop(flatBufBytes);

				auto ret_UserInfoFB = UserInfoFB.getRootAsUserInfoFB(new ByteBuffer(flatBufBytes));
				//input flatbuffer code for UserInfoFB class




				ret_UserInfo.i = ret_UserInfoFB.i;
		ret_UserInfo.name = ret_UserInfoFB.name;


				rpcCallback(ret_UserInfo);
			}else{
				throw new Exception("rpc sync call error, function:" ~ RpcBindFunctionMap[funcId]);
			}}, RPC_PACKAGE_PROTOCOL.TPP_FLAT_BUF, funcId);
	}


	RpcClientImpl!(RpcTestService) rpImpl;
}


