#include <jni.h>
#include <string>
#include <node.h>

extern "C" JNIEXPORT jint JNICALL
Java_com_kira_app_NodeBridge_startNode(JNIEnv* env, jobject /* this */, jobjectArray-strings) {
    int argc = env->GetArrayLength(strings);
    char** argv = new char*[argc];
    for (int i = 0; i < argc; i++) {
        jstring string = (jstring)env->GetObjectArrayElement(strings, i);
        const char* rawString = env->GetStringUTFChars(string, 0);
        argv[i] = new char[strlen(rawString) + 1];
        strcpy(argv[i], rawString);
        env->ReleaseStringUTFChars(string, rawString);
    }

    int result = node::Start(argc, argv);

    for (int i = 0; i < argc; i++) {
        delete[] argv[i];
    }
    delete[] argv;

    return result;
}
