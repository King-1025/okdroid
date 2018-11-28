#描述:构建apk
#时间:2018.11.24

PROJECT_NAME=okdroid
PROJECT_PATH=$(shell pwd)
ANDROID_SOURCE_DIR=$(PROJECT_PATH)/source
ANDROID_NATIVE_DIR=$(PROJECT_PATH)/native
ANDROID_RESOURCE_DIR=$(PROJECT_PATH)/res
ANDROID_SIGN_DIR=$(PROJECT_PATH)/sign
ANDROID_MANIFEST_FILE=$(PROJECT_PATH)/AndroidManifest.xml

APK_TYPE=debug
APK_VERSION=0.1
APK_SIGN_FILE=$(ANDROID_SIGN_DIR)/$(APK_TYPE).jks
APK_NAME=$(PROJECT_NAME)-$(APK_TYPE)-$(APK_VERSION).apk

BUILD_DIR=$(PROJECT_PATH)/build
OUTPUT_DIR=$(PROJECT_PATH)/output

#sdk路径
SDK_PATH=$(ANDROID_HOME)
#tools路径
TOOLS_PATH=$(SDK_PATH)/tools
#platforms路径
PLATFORMS_PATH=$(SDK_PATH)/platforms/android-28
#build-tools版本路径
BUILD_TOOLS_PATH=$(SDK_PATH)/build-tools/28.0.3
#android.jar路径
ANDROID_JAR=$(PLATFORMS_PATH)/android.jar
#java路径
JAVA=$(shell which java)
#javac路径
JAVAC=$(shell which javac)
#javah路径
JAVAH=$(shell which javah)
#aapt路径
AAPT=$(shell which aapt)
#aidl路径
AIDL=$(shell which aidl)
#dx路径
DX=$(BUILD_TOOLS_PATH)/dx
APK_BUILDER=$(JAVA) -cp $(TOOLS_PATH)/lib/sdklib-26.0.0-dev.jar com.android.sdklib.build.ApkBuilderMain
APK_SIGNER=$(BUILD_TOOLS_PATH)/apksigner

SEARCH_SOURCE_FILES=find $(ANDROID_SOURCE_DIR) -type f -name *.java -print
EXTRA_SOURCE_FILES=

NATIVE_LIBRARY_DIR=$(PROJECT_PATH)/jniLibs
JNI_LIST=$(PROJECT_PATH)/jni.list

JAVA_COMPILE_OPTIONS=-cp $(ANDROID_JAR) -verbose

TARGET_RESOURCE=$(BUILD_DIR)/resources.ap_
TARGET_DEX=$(BUILD_DIR)/classes.dex

.PHONY: clean

all: init verify_apk
	@echo "构建完成,输出文件:$(OUTPUT_DIR)/$(APK_NAME)"

init:
	@echo "开始构建..."

#更新头文件
update_H: $(JNI_LIST) javac_generate_class 	
	@mkdir -p $(ANDROID_NATIVE_DIR)/include
	$(JAVAH) -force -d $(ANDROID_NATIVE_DIR)/include -cp $(BUILD_DIR)/class -jni $(shell cat $(JNI_LIST))

#更新R.java
update_R: $(ANDROID_MANIFEST_FILE) $(ANDROID_JAR) $(ANDROID_RESOURCE_DIR) $(ANDROID_SOURCE_DIR)
	$(AAPT) package -f -m --auto-add-overlay -M $(ANDROID_MANIFEST_FILE) -I $(ANDROID_JAR) -S $(ANDROID_RESOURCE_DIR) -J $(ANDROID_SOURCE_DIR)

#编译java文件
javac_generate_class: update_R
	@mkdir -p $(BUILD_DIR)/class
	$(JAVAC) $(JAVA_COMPILE_OPTIONS) -d $(BUILD_DIR)/class $(shell $(SEARCH_SOURCE_FILES)) $(EXTRA_SOURCE_FILES)

#生成classes.dex
$(TARGET_DEX): javac_generate_class
	$(DX) --dex --output=$(TARGET_DEX) $(BUILD_DIR)/class

#使用aapt将资源文件打包
$(TARGET_RESOURCE): $(ANDROID_MANIFEST_FILE) $(ANDROID_JAR) $(ANDROID_RESOURCE_DIR)
	$(AAPT) package -f -M $(ANDROID_MANIFEST_FILE) -I $(ANDROID_JAR) -S $(ANDROID_RESOURCE_DIR) -F $(TARGET_RESOURCE)

#构建apk文件
build_apk: $(TARGET_DEX) $(TARGET_RESOURCE)
	$(APK_BUILDER) $(BUILD_DIR)/out.apk  -v -u -f $(TARGET_DEX) -z $(TARGET_RESOURCE) -nf $(NATIVE_LIBRARY_DIR)

#签名apk文件
sign_apk: build_apk
	@mkdir -p $(OUTPUT_DIR)
	$(APK_SIGNER) sign -v --ks $(APK_SIGN_FILE) --in $(BUILD_DIR)/out.apk --out $(OUTPUT_DIR)/$(APK_NAME) --ks-pass file:$(ANDROID_SIGN_DIR)/debug_ks_pass

verify_apk: sign_apk
	$(APK_SIGNER) verify -v $(OUTPUT_DIR)/$(APK_NAME)

clean:
	@rm -rf $(BUILD_DIR)
	@rm -rf $(OUTPUT_DIR)
