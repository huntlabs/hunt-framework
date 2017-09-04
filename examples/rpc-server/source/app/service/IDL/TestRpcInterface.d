module KissRpc.IDL.TestRpcInterface;

import KissRpc.IDL.TestRpcMessage;
import KissRpc.IDL.TestRpcService;

import KissRpc.RpcServer;
import KissRpc.RpcServerImpl;
import KissRpc.RpcResponse;
import KissRpc.RpcRequest;
import flatbuffers;
import KissRpc.IDL.flatbuffer.TestRpc;

import std.stdio;

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


