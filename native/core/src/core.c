#include <stdio.h>
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
	char *msg=(char *)malloc(cmd_size+30);
	int ret=system(cmd);
	sprintf(msg,"ret:%d cmd_size:%d cmd:%.*s",ret,cmd_size,cmd_size,cmd);
	/*
	FILE *fp=fopen("./okdroid.txt","w+");
	if(fp!=NULL){
	  fprintf(fp,"%.*s",sizeof(msg),msg);
	}*/

	str =(*env) -> NewStringUTF(env,msg);

	(*env) -> ReleaseStringUTFChars(env,command,cmd);
	free(msg);
	free(fp);

/*	if (ret==0){
	   str =(*env) -> NewStringUTF(env,"执行成功"); 
	}else{
	   str =(*env) -> NewStringUTF(env,"执行失败"); 
	}
*/
    }
    return str;
}
