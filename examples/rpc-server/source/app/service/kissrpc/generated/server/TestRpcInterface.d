module kissrpc.generated.TestRpcInterface;

import kissrpc.generated.TestRpcMessage;
import kissrpc.generated.TestRpcService;

import kissrpc.RpcServer;
import kissrpc.RpcServerImpl;
import kissrpc.RpcResponse;
import kissrpc.RpcRequest;
import flatbuffers;
import kissrpc.generated.message.TestRpc;

abstract class RpcTestInterface{ 

	this(RpcServer rpServer){ 
		rpImpl = new RpcServerImpl!(RpcTestService)(rpServer); 
		rpImpl.bindRequestCallback(2791659981, &this.getNameInterface); 

	}

	void getNameInterface(RpcRequest req){

		ubyte[] flatBufBytes;

		auto resp = new RpcResponse(req);
		req.pop(flatBufBytes);

		auto userInfoFB = UserInfoFB.getRootAsUserInfoFB(new ByteBuffer(flatBufBytes));
		UserInfo userInfo;

		//input flatbuffer code for UserInfoFB class



				userInfo.i = userInfoFB.i;
		userInfo.name = userInfoFB.name;


		auto ret_UserInfo = (cast(RpcTestService)this).getName(userInfo);

		auto builder = new FlatBufferBuilder(512);
		//input flatbuffer code for UserInfoFB class

				auto ret_UserInfoPos = UserInfoFB.createUserInfoFB(builder, ret_UserInfo.i, builder.createString(ret_UserInfo.name), );


		builder.finish(ret_UserInfoPos);

		resp.push(builder.sizedByteArray);

		rpImpl.response(resp);
	}



	RpcServerImpl!(RpcTestService) rpImpl;
}


