module kissrpc.generated.TestRpcService;

import kissrpc.generated.TestRpcInterface;
import kissrpc.generated.TestRpcMessage;

import kissrpc.RpcServer;
import kissrpc.Unit;


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



