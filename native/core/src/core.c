#include "jni.h"
#include "jni_md.h"
#include "king_demo_Native.h"

JNIEXPORT jstring JNICALL Java_king_demo_Native_sendJavaMessage                (JNIEnv *env, jclass clazz)
{
    jstring str =(*env) -> NewStringUTF(env,"native"); 
    return str;
}
