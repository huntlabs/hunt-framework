module KissRpc.IDL.TestRpcService;

import KissRpc.IDL.TestRpcInterface;
import KissRpc.IDL.TestRpcMessage;

import KissRpc.RpcServer;
import KissRpc.Unit;


class RpcTestService: RpcTestInterface{

	this(RpcServer rpServer){
		RpcBindFunctionMap[2791659981] = typeid(&RpcTestService.getName).toString();
		super(rpServer);
	}

	UserInfo getName(UserInfo userInfo){

		UserInfo userInfoRet = userInfo;
		//input service code for UserInfo class

		return userInfoRet;
	}



}



