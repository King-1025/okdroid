#include <stdlib.h>

#include "jni.h"
#include "jni_md.h"
#include "king_demo_Native.h"

JNIEXPORT jstring JNICALL Java_king_demo_Native_exec
(JNIEnv *env, jclass clazz,jstring command)
{
    jstring str=NULL;
    if (command!=NULL){
	const char *cmd=(*env) -> GetStringUTFChars
		(env,command,(unsigned char *)0);
	int cmd_size=(int)sizeof(cmd);
	char *msg=(char *)malloc(cmd_size+20);
	int ret=system(cmd);
	sprintf(msg,"%d ---> %.*s",ret,cmd_size,cmd);
	//sprintf(msg,"执行失败！%.*s",(int)sizeof(cmd),cmd);
	str =(*env) -> NewStringUTF(env,msg);
	free(msg);
	(*env) -> ReleaseStringUTFChars(env,command,cmd);
/*	if (ret==0){
	   str =(*env) -> NewStringUTF(env,"执行成功"); 
	}else{
	   str =(*env) -> NewStringUTF(env,"执行失败"); 
	}
*/
    }
    return str;
}
