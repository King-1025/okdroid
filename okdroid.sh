#!/usr/bin/env bash

android_app=app
android_java_source=$android_app/src/java
android_resource=$android_app/res
android_assert=$android_app/assert
android_manifest_xml=$android_app/AndroidManifest.xml

android_native=native
android_native_bin=$android_native/bin
android_native_library=$android_native/lib
android_native_include=$android_native/include

android_build=build
android_resource_R=$android_build/R
android_classes=$android_build/classes
android_dex_output=$android_build/classes.dex
android_resource_output=$android_build/resources.ap_
android_apk_output=$android_build/out.apk

android_sign=sign
android_debug_jks=$android_sign/debug.jks
android_release_jks=$android_sign/release.jks

android_extra=extra
android_extra_java_source=$android_extra/java
android_extra_classes=$android_extra/classes

apk_output=output
support_tools=tools

default_apk_name=signed-debug.apk
default_sign_jks=${android_debug_jks}

android_jar=$KALI_HOME/opt/android-sdk-linux/platforms/android-28/android.jar
android_jar=tools/lib/android-28.jar
jni_list=./jni.list

java_compile_options="-cp ${android_jar}"
android_aapt_options="-I ${android_jar}"
android_sign_options="--ks-pass file:${android_sign}/debug_ks_pass"

okdroid=~/.okdroid
okdroid_project_list=$okdroid/project.list
okdroid_step_force=0
okdroid_all_steps=0
okdroid_current_step=0

#远程处理
#apkbuilder_input
#apkbuilder_handle
#apksigner_input
#apksigner_handle
#jni_header_input
#jni_header_handle

function app()
{
  if [ $1 -eq 0 ]; then
     android_build_step
  else
    declare -a argv=($2)
    for ((i=0;i<$1;i++));do
      #echo "$i:${argv[i]}"
      case "${argv[i]}" in
	 "init") init_okdroid; break;;
	 "view") view_project; break;;
	 "create") create_project; break;;
	 
	 "reset") reset_okdroid;;
	 "clean") clean_project;;
	 "force") okdroid_step_force=1;;
	 "remote") set_remote_tools;;
	 
	 "R") update_resource_R; break;;
	 "H") update_native_include; break;;
	 "class") compile_java_classes; break;;
	 "last") build_apk; sign_apk; break;;
	 "sign") sign_apk; break;;
	 "verify") verify_apk; break;;
	 "apk") android_build_step; break;;
	 "help") user_help; break;;
      esac
    done
    unset i
  fi
}

function user_help()
{
  echo "support:init,clean,reset,view,create,force,apk,sign,verify,R,H,class,remote,last,help"
}

function set_remote_tools()
{
   java_compiler="remote_tool javac"
   android_aapt_R="aapt"
   android_aapt_P="aapt"
   android_dx="remote_tool dx"
   android_apk_builder="remote_tool apkbuilder"
   android_apk_sign="remote_tool apk_sign"
   android_apk_verify="remote_tool apk_verify"
}

function remote_tool()
{
  if [ $# -eq 1 ]; then
     local tag=$1
     local remote="upss -dt -dh -r -e ssh"
     local input=""
     local handle=""
     local output=""
     local build="$(basename $(mktemp -u))"
     local rpt=.tmp/okdroid/remote
     local path=/home/test0/ftp/okdroid/remote
     local ajr=$path/../tool/lib/android.jar
     local dx=$path/../tool/dx
     local apb=$path/../tool/apkbuilder
     local aks=$path/../tool/apksigner
     case "$tag" in
	"aapt_r")
	    input="${android_manifest_xml} ${android_resource}"
            handle="aapt package -f -m --auto-add-overlay -M ${android_manifest_xml} -S ${android_resource} -J ${build} -I $ajr"
	    output="${android_resource_R}"
	;;
        "aapt_p")
	    input="${android_manifest_xml} ${android_resource}"
	    handle="aapt package -f -M ${android_manifest_xml} -S ${android_resource} -F ${build}/$(basename ${android_resource_output}) -I $ajr"
	    output="$(dirname ${android_resource_output})"
	;;
        "javac")
	    input="${android_java_source}"
	    handle="javac -d ${build} -cp $ajr ${android_java_source}"
	    output="${android_classes}"
	;;
        "dx")
	    input="${android_classes}"
	    handle="$dx --dex --output=${build}/$(basename ${android_dex_output}) ${android_classes}"
	    output="$(dirname ${android_dex_output})"
	;;
        "apkbuilder")
	    input="${apkbuilder_input}"
	    handle="$apb ${build}/$(basename ${android_apk_output}) -v -u ${apkbuilder_handle}"
	    output="$(dirname ${android_apk_output})"
	;;
        "apk_sign")
	    input="${apksigner_input}"
	    handle="$aks sign --out ${build}/${apk_name} ${apksigner_handle}"
	    output="${apk_output}"
	;;
        "apk_verify")
	    input="${apksigner_input}"
	    handle="$aks verify ${apksigner_handle}"
	    output=""
	;;
        "javah")
	    input="${jni_header_input}"
            handle="javah -d ${build} ${jni_header_handle}"
	    output="${android_native_include}"
	;;
     esac
     if [ "$input" != "" ]&&[ "$handle" != "" ]; then
        local tmp=$(mktemp -u)
	local wk=$(basename $tmp)
	tar -czf ${tmp} ${input}	
	if [ -e "$tmp" ]; then
	   sf put $rpt/$wk.tgz $tmp
	   $remote "cd $path;
	            mkdir -p $wk;
		    mv $wk.tgz $wk;
		    cd $wk;
	            tar -xzf $wk.tgz;
		    mkdir -p $build;
		    $handle;
		    tar -czf $path/$wk.tgz $build;
		    cd $path;
                    rm -rf $wk;"
	   if [ "$output" != "" ]; then
	      sf get $tmp $rpt/$wk.tgz
	      mkdir -p ${output}
              tar -xzf ${tmp}
	      mv ${build}/* ${output}/
	      rm -rf $build
	   fi
	   rm -rf $tmp
	   $remote "rm -rf $path/$wk.tgz" 
	fi
      fi
  fi
}

function android_build_step()
{
  okdroid_all_steps=7
  okdroid_current_step=1
  assert update_resource_R "更新R.java"
  assert compile_java_classes "编译源文件"
  assert make_classes_dex "生成.dex"
  assert make_resources_package "打包资源"
  assert build_apk "构建apk"
  assert sign_apk "签名apk"
#  assert verify_apk "校验apk"
}

function assert()
{
  if [ $# -eq 2 ]; then
     local step=$1
     local tag=$2
     local all_steps=${okdroid_all_steps}
     local current_step=${okdroid_current_step}
     if [ "$all_steps" = "" ]; then all_steps="*"; fi
     if [ "$current_step" = "" ]; then current_step="*"; fi 
     echo "$step(${all_steps}/${current_step})" && $step
     if [ $? -ne 0 ]&&[ ${okdroid_step_force} -ne 1 ]; then
	while true; do
	   read -p "$tag faild! do you want to continue next step?(yes/no)" option
	   case "$option" in
		"yes") break;;
		"no") exit 0;;
		"*") continue;;
	   esac
        done
     fi
     if [ "$current_step" != "*" ]; then
	if [ "$current_step" = "$all_steps" ]; then exit 0; fi
        ((current_step++)) > /dev/null 2>&1
	if [ $? -eq 0 ]; then
	   okdroid_current_step=$current_step
        fi
     fi
     printf "\n"
  else
    echo "assert needs 2 arguments!"
  fi
}

function verify_apk()
{
  echo "=> start to verify apk..."
  handle_apk "verify"
}

function sign_apk()
{
  echo "=> start to sign apk..."
  handle_apk "sign"
}

function handle_apk()
{
  local is=1
  if [ $# -eq 1 ]; then
     local intent=$1
     local apk_signer=""
     case "$intent" in
	"sign")
	    apk_signer=$(check_tool "apksigner" "${android_apk_sign}" "android apk signer" "apk_sign")
	;;
        "verify")
            apk_signer=$(check_tool "apksigner" "${android_apk_verify}" "android apk signer" "apk_verify")
	;;
     esac
     if [ "$apk_signer" != "" ]; then
        local comm="$apk_signer"
        case "$intent" in
	   "sign")
	      mkdir -p ${apk_output}
              local sign_jks=$(check_file "${default_sign_jks}" "android default sign file")
	      local apk_name=${default_apk_name}
	      if [ "${apk_name}" = "" ]; then
		 while true; do
		     read -p "please input signed apk name:" apk_name
		     if [ "${apk_name}" != "" ]; then break; fi
		 done
	      fi 
	      echo "$comm" | grep -E "^remote_tool"
	      if [ $? -ne 0 ]; then
                 comm="$apk_signer sign -v --ks ${sign_jks} --in ${android_apk_output} --out ${apk_output}/${apk_name} ${android_sign_options}"
	     else
                 apksigner_input="${sign_jks} ${android_apk_output} ${android_sign}/debug_ks_pass"
		 apksigner_handle=" -v --ks ${sign_jks} --in ${android_apk_output} ${android_sign_options}"
	     fi
            ;;
	    "verify")
	      local apk=$(check_file "${apk_output}/${default_apk_name}" "apk")
              echo "$comm" | grep -E "^remote_tool"
	      if [ $? -ne 0 ]; then
                 comm="$apk_signer verify -v $apk"
	      else
                 apksigner_input="$apk"
		 apksigner_handle=" -v $apk"
	      fi
	    ;;
	esac
	if [ "$comm" != "" ]; then
	   echo $comm && $comm
	   is=$?
	fi
      fi
  fi
  return $is
}

function build_apk()
{
  local is=1
  echo "=> start to build apk..."
  local apk_builder=$(check_tool "apkbuilder" "${android_apk_builder}" "android apk builder" "apkbuilder")
  if [ "$apk_builder" != "" ]; then
     local dex=$(check_file "${android_dex_output}" "android dex")
     local pkg=$(check_file "${android_resource_output}" "android resource package")
     if [ "$dex" != "" ]&&[ "$pkg" != "" ]; then
	mkdir -p $(dirname ${android_apk_output})
        local comm="$apk_builder"
	echo "$comm" | grep -E "^remote_tool"
	if [ $? -ne 0 ]; then
           comm+=" ${android_apk_output} -v -u -f ${dex} -z ${pkg}"
	   if [ -e "${android_native_library}" ]; then
	       comm+=" -nf ${android_native_library}"
	   fi
	else
	   apkbuilder_input="${dex} ${pkg}"
	   apkbuilder_handle="-f ${dex} -z ${pkg}"
	   if [ -e "${android_native_library}" ]; then
	       apkbuilder_input+=" ${android_native_library}"
	       apkbuilder_handle+=" -nf ${android_native_library}"
	   fi
        fi
	if [ "$comm" != "" ]; then
	   echo "$comm" && $comm
	   is=$?
	fi
     fi
  fi
  return $is
}

function make_resources_package()
{
  echo "=> start to make resources package..."
  aapt_resource "make_pkg"
}

function update_native_include()
{
  okdroid_all_steps=2
  okdroid_current_step=1
  java_compiler="remote_tool javac"
  javah="remote_tool javah"
  rm -rf ${android_classes}
  assert compile_java_classes "编译源文件"
  assert update_jni_header "更新jni头文件"
}

function update_jni_header()
{
  local is=1
  echo "=> start to update jni header..."
  local javah=$(check_tool "javah" "${javah}" "javah" "javah")
  if [ "$javah" != "" ]; then
     local classes=$(check_file "${android_classes}" "android classes")
     local jni_list=$(check_file "${jni_list}" "jni list file")
     if [ "$classes" != "" ]&&[ "$jni_list" != "" ]; then
	mkdir -p ${android_native_include}
	rm -rf ${android_native_include}/*.h
        local comm="$javah"
	echo "$comm" | grep -E "^remote_tool"
	if [ $? -ne 0 ]; then
           comm+=" -force -d ${android_native_include} -cp ${classes}:${android_extra_classes} -jni $(cat $jni_list)"
	else
           jni_header_input="${classes} ${android_extra_classes}"
	   jni_header_handle="-force -cp ${classes}:${android_extra_classes} -jni $(cat $jni_list)"
	fi
	if [ "$comm" != "" ]; then
	   echo "$comm" && $comm
	   is=$?
	fi
     else
	echo "please checkout requirements for update jni header."
     fi
  fi
  return $is
}

function make_classes_dex()
{
  local is=1
  echo "=> start to make classes dex..."
  local dx=$(check_tool "dx" "${android_dx}" "android dx" "dx")
  if [ "$dx" != "" ]; then
     local classes=$(check_file "${android_classes}" "android classes")
     if [ "$classes" != "" ]; then
        local comm="$dx"
	echo "$comm" | grep -E "^remote_tool"
	if [ $? -ne 0 ]; then
           comm+=" --dex --output=${android_dex_output} ${classes} ${android_extra_classes}"
	else
           android_classes="${classes} ${android_extra_classes}"
	fi
	if [ "$comm" != "" ]; then
	   echo "$comm" && $comm
	   is=$?
        fi
     fi
  fi
  return $is
}

function compile_java_classes()
{
  local is=1
  echo "=> start to compile java classes..."
  local javac=$(check_tool "javac" "${java_compiler}" "java compile" "javac")
  local all=""
  if [ "$javac" != "" ]; then
     local src=$(check_file "${android_java_source}" "java source")
     local resR=$(check_file "${android_resource_R}" "resource R")
     if [ "$src" != "" ]&&[ "$resR" != "" ]; then
	local origin=$(mktemp -u)
	local target=$(mktemp -u)
	local clean=$(mktemp -u)
        local state=${android_classes}/.status_md5sum
	find "$src" -type f -name "*.java" -print > $origin
	find "$resR" -type f -name "R.java" -print >> $origin
	find "${android_extra_java_source}" -type f -name "*.java" -print >> $origin
	all=$(cat $origin)
        handle_source $origin $target $clean $state
        local all=$(cat $origin)
	if [ -e "$clean" ]; then
	   #set -x
	   local slen=${#android_java_source}
	   local elen=${#android_extra_java_source}
           while read line; do
              rm -rf ${android_classes}/${line:$slen:-5}*.class
              rm -rf ${android_classes}/${line:$elen:-5}*.class
	   done < $clean
	   #set +x
	   rm -rf "$clean" > /dev/null 2>&1
	fi
        if [ -e "$target" ]; then
	   local list=$(cat $target)
	   if [ "$list" = "up-to-date" ]; then
	       list=""
               is=0
           fi
	   if [ "$list" != "" ]; then
	      local comm="$javac"
	      echo "$comm" | grep -E "^remote_tool"
	      if [ $? -ne 0 ]; then
                 comm+=" -d ${android_classes} ${java_compile_options} ${list}"
	      else
		 rm -rf ${android_classes} 
                 android_java_source=$all 
	      fi
	      if [ "$comm" != "" ]; then
                 echo "$comm" && $comm
	         is=$?
	      fi
	   #else
	      #echo "not found any compileble java source files!"
           fi
 	   rm -rf "$target" > /dev/null 2>&1
        fi
	rm -rf "$origin" > /dev/null 2>&1
     else
	echo "please checkout requirements for compile java classes."
     fi
  fi
  return $is
}

function update_resource_R()
{
  echo "=> start to update resource R..."
  aapt_resource "create_R"
}

function aapt_resource()
{
  local is=1
  if [ $# -eq 1 ]; then
     local intent=$1
     local aapt=""
     case "$intent" in
	"create_R")
	    aapt=$(check_tool "aapt" "${android_aapt_R}" "aapt" "aapt_r")
	;;
        "make_pkg")
	    aapt=$(check_tool "aapt" "${android_aapt_P}" "aapt" "aapt_p")
	;;
     esac
     if [ "$aapt" != "" ]; then
        local manifest=$(check_file "${android_manifest_xml}" "AndroidManifest.xml")
        local res=$(check_file "${android_resource}" "android resource") 
        if [ "$manifest" != "" ]&&[ "$res" != "" ]; then
	   local comm="$aapt"
	   echo "$comm" | grep -E "^remote_tool"
	   if [ $? -ne 0 ]; then
	     case "$intent" in
	        "create_R")
                    mkdir -p ${android_resource_R}
                    comm+=" package -f -m --auto-add-overlay -M "${manifest}" -S "${res}" -J "${android_resource_R}" ${android_aapt_options}"
	        ;;
                "make_pkg")
		    mkdir -p $(dirname ${android_resource_output})
                    comm+=" package -f -M "${manifest}" -S "${res}" -F "${android_resource_output}" ${android_aapt_options}"
	        ;;
	      esac
	   else
	      android_manifest_xml=${manifest}
	      android_resource=${res}
           fi
	   if [ "$comm" != "" ]; then
	      echo $comm && $comm
	      is=$?
	   fi
        else
	   echo "please checkout requirements for android aapt resource"
        fi
     fi
  fi
  return $is
}

function handle_source()
{
  if [ $# -eq 4 ]; then
   if [ -e "$1" ]; then
     local save=$2
     local clean=$3
     local state=$4
     declare -a target=()
     declare -a origin=($(cat $1))
     local size=${#origin[@]}
     if [ ! -e "$state" ]; then
	target=${origin[@]}
     else
        local check=$(mktemp -u)
	md5sum -c "$state" > "$check" 2>&1
	if [ -e "$check" ]; then
	   local ch=0; local up=0; local ne=0; local de=0
	   sed -i "/^md5sum:/d" "$check"
  	   sed -i "s/: /*/g" "$check"
           for((i=0,j=0;i<$size;i++)); do
             local item=${origin[i]}
  	     local isOk=$(cat "$check" | awk -F "*" -v item="$item" '{if($1 == item)print $2}')
	     local isAdd=0
	     if [ "$isOk" != "" ]; then
  	        if [ "$isOk" != "OK" ]; then
		   isAdd=1
		   printf "\e[1;33m%-5s ===> %s\e[m\n" ":changed" "$item"
		   ((ch++))
		else
		   printf "\e[1;37m%-5s ===> %s\e[m\n" ":up-to-date" "$item"
		   ((up++))
		fi
                local rgx=$(echo "$item" | sed "s/\//\./g")
  		sed -i "/$rgx/d" "$check"
	     else
		isAdd=1
		printf "\e[1;34m%-5s ===> %s\e[m\n"  ":new" "$item"
		((ne++))
  	     fi
             if [ "$isAdd" -eq 1 ]; then
  	        target[j]=$item
  		((j++))
             fi
  	   done
	   declare -a delist=($(cat "$check" | awk -F "*" '{print $1}'))
	   de=${#delist[@]}
           rm -rf "$clean" > /dev/null 2>&1
	   for((i=0;i<$de;i++)); do
	     local item=${delist[i]}
	     echo "$item" >> $clean
	     printf "\e[1;31m%-5s ===> %s\e[m\n"  ":deleted" "$item"
	   done
	   unset i; unset j
  	   rm -rf "$check"
	   printf "\e[1;37m::origin:$size\e[m \e[1;33mchanged:$ch\e[m \e[1;37mup-to-date:$up\e[m \e[1;34mnew:$ne\e[m \e[1;31mdeleted:$de\e[m\n"
	   if [ "$size" = "$up" ]&&[ "${#target[@]}" -eq 0 ]; then
	      target=("up-to-date")
	   fi
        else
	   printf "${state} maybe bad,skip!\n"
	   target=${origin[@]}
	fi
     fi
     if [ $size -gt 0 ]; then
        mkdir -p $(dirname "$state")
        md5sum "${origin[@]}" > "$state"
     fi
     size=${#target[@]}
     rm -rf "$save" > /dev/null 2>&1
     for ((i=0;i<$size;i++)); do
        echo "${target[i]}" >> "$save"
     done
     unset i
   fi
  fi
}

function check_file()
{
   local file=""
   if [ $# -eq 2 ]; then
     file=$1
     if [ ! -e "$1" ]; then
	read -p "$2($1) isn't exist! would you like to reset it?(yes/no)" option
        case "$option" in
	     "yes") read -p "please input $2 path:" file;;
	     "no") file="";;
	      * ) exit 0 ;;
        esac
        unset option
     fi
  fi
  echo "$file"
}

function check_tool()
{
  local tool=""
  if [ $# -eq 4 ]; then
     tool=$1
     if [ "$2" != "" ]; then
	tool=$2
     else
       which $tool > /dev/null 2>&1
       if [ $? -ne 0 ]; then
	  read -p "sorry,not found $3 tool.would you like to try remote $3 tool?(yes/no)" option
          case "$option" in
	     "yes") tool="remote_tool $4" ;;
	     "no") tool="";;
	      * ) exit 0 ;;
          esac
	  unset option
       fi
    fi
  fi
  echo "$tool"
}

function init_okdroid()
{
  mkdir -p ${okdroid} 
}

function reset_okdroid()
{
  rm -rf ${okdroid_project_list}
}

function clean_project()
{
  rm -rf ${android_build}
  rm -rf ${apk_output}
  rm -rf ${android_native_include}/*.h
}

function view_project()
{
  if [ ! -e ${okdroid_project_list} ]; then
     read -p "sorry,not found any projects,do you want to create some?(yes/no)" option
     case "$option" in
	  "yes") create_project ;;
	   "no") echo "ok! you can also add projects in ${okdroid_project_list}" ;;
	    * ) exit 0 ;;
     esac
     unset option
  else
     declare -a plist=($(cat ${okdroid_project_list} | awk '{print $4}'))
     local count=0
     for ((i=0;i<${#plist[@]};i++)); do
        local ppa=${plist[i]}
        if [ -e "$ppa" ]; then
	   ((count++))
	else
	   local rgx=$(echo "$ppa" | sed "s/\//\./g")
	   sed -i "/$rgx/d" ${okdroid_project_list}
	fi
     done
     echo "project total:$count"
     if [ $count -gt 0 ]; then
       cat ${okdroid_project_list}
     else
       rm -rf ${okdroid_project_list}
     fi
  fi
}

function create_project()
{
   local count=1
   local tmpf=$(mktemp -u)
   local current=$(pwd)
   mkdir -p ${okdroid}
   while true; do
      cd $current
      read -p "please input project location:" location
      if [ -e "$location" ]; then
	 read -p "$location is in use,do you want to overwrite? (yes/no)" option
	 case "$option" in
	      "yes") rm -rf $location ;;
	      "no") continue ;;
	       * ) exit 0 ;;
         esac
      fi
      mkdir -p $location && cd $location
      mkdir -p ${android_java_source}
      mkdir -p ${android_resource}
      mkdir -p ${android_assert}
      read  -p "would you like to create native directories?(yes/no)" option
      case "$option" in
	   "yes") 
		 mkdir -p ${android_native_bin}
		 mkdir -p ${android_native_library}
		 mkdir -p ${android_native_include}
	   ;;
	   "no") echo "project $location without native directories" ;;
	    * ) exit 0 ;;
      esac
      mkdir -p ${android_sign}
      mkdir -p ${android_extra_java_source}
      mkdir -p ${android_extra_classes}
      mkdir -p ${support_tools}
      tree  -a $(pwd)
      echo "$(whoami) $(date "+%F %H:%M:%S") $(pwd)" >> ${okdroid_project_list}
      echo "$count ---> $(pwd)" >> $tmpf
      read  -p "project ${location} is ok! continue to create next?(yes/no)" option
      case "$option" in
	    "yes") ((count++));;
	    "no") echo "project total:$count"; cat $tmpf; break;;
	     * ) exit 0 ;;
      esac
      echo "***"
   done
   unset option
   unset location
   rm -rf $tmpf > /dev/null 2>&1
}

app "$#" "$*"
