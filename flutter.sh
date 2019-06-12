#!/bin/bash
# This is flutter build

# 初始化记录项目pwd
projectDir=`pwd`
# 获取 flutter sdk
rootFlutter=`which flutter`
# 提取 flutter skd路径
rootDir=${rootFlutter%/*}
# 获取

# 假如没有引用三方的flutter Plugin 设置false 即可 *************************
isPlugin=false

# targetSDK 设置为 26
if [ `grep -c 'targetSdkVersion 26' .android/app/build.gradle` -eq '1' ]; then
     echo "targetSDK 已经是26 ，不需要修改"
else
     echo "targetSDK 需要修改为 26 "
     sed -i '' 's/targetSdkVersion 28/targetSdkVersion 26/g' .android/app/build.gradle
fi

# 版本号 + 1
cd ${projectDir}
v=`grep sonatypeVersion bak/gradle.properties|cut -d'=' -f2`
echo 旧版本号$v
v1=`echo | awk '{split("'$v'",array,"."); print array[1]}'`
v2=`echo | awk '{split("'$v'",array,"."); print array[2]}'`
v3=`echo | awk '{split("'$v'",array,"."); print array[3]}'`
v4=`echo | awk '{split("'$v'",array,"."); print array[4]}'`
y=`expr $v4 + 1`

vv=$v1"."$v2"."$v3"."$y
echo 新版本号$vv
# 更新配置文件
sed -i '' 's/sonatypeVersion='$v'/sonatypeVersion='$vv'/g' bak/gradle.properties
if [ $? -eq 0 ]; then
    echo ''
else
    echo '更新版本号失败...'
    exit
fi

# 删除 fat-aar 引用
function delFatAarConfig() {
    if [  ${isPlugin} == false  ]; then
        echo '删除 fat-aar 引用........未配置三方插件'
    else :
        cd ${projectDir} # 回到项目
        echo '删除 fat-aar 引用 ... '
        sed -i '' '$d
            ' .android/settings.gradle
        sed -i '' '$d
            ' .android/Flutter/build.gradle
        sed -i '' '$d
            ' .android/Flutter/build.gradle
        sed -i '' '11 d
            ' .android/build.gradle
    fi
}

# 引入fat-aar
function addFatAArConfig() {
     if [  ${isPlugin} == false  ]; then
        echo '引入fat-aar 配置........未配置三方插件'
     else :
        cd ${projectDir} # 回到项目

        cp bak/setting_gradle_plugin.gradle .android/config/setting_gradle_plugin.gradle

        if [ `grep -c 'setting_gradle_plugin.gradle' .android/settings.gradle` -eq '1' ]; then
            echo ".android/settings.gradle 中 已存在 ！！！"
        else
            echo ".android/settings.gradle 中 不存在，去编辑"
            sed -i '' '$a\
            apply from: "./config/setting_gradle_plugin.gradle"
            ' .android/settings.gradle
        fi

        if [ $? -eq 0 ]; then
            echo '.android/settings.gradle 中 脚本插入 fat-aar 成功 !!!'
        else
            echo '.android/settings.gradle 中 脚本插入 fat-aar 出错 !!!'
            exit 1
        fi

        if [ `grep -c 'com.kezong:fat-aar' .android/build.gradle` -eq '1' ]; then
            echo "com.kezong:fat-aar:1.0.3 已存在 ！！！"
        else
            echo "com.kezong:fat-aar:1.0.3 不存在，去添加"
            sed -i '' '10 a\
            classpath "com.kezong:fat-aar:1.0.3"
            ' .android/build.gradle
        fi

        # flutter/build.gradle 中添加fat-aar 依赖 和 dependencies_gradle_plugin
        if [ `grep -c "com.kezong.fat-aar" .android/Flutter/build.gradle` -eq '1' ]; then
            echo "Flutter/build.gradle 中 com.kezong:fat-aar 已存在 ！！！"
        else
            echo "Flutter/build.gradle 中 com.kezong:fat-aar 不存在，去添加"
            sed -i '' '$a\
            apply plugin: "com.kezong.fat-aar"
            ' .android/Flutter/build.gradle
        fi

        cp bak/dependencies_gradle_plugin.gradle .android/config/dependencies_gradle_plugin.gradle
        if [ `grep -c 'dependencies_gradle_plugin' .android/Flutter/build.gradle` -eq '1' ]; then
            echo "Flutter/build.gradle 中 dependencies_gradle_plugin.gradle 已存在 ！！！"
        else
            echo "Flutter/build.gradle 中 dependencies_gradle_plugin.gradle 不存在，去添加"
            sed -i '' '$a\
            apply from: "../config/dependencies_gradle_plugin.gradle"
            ' .android/Flutter/build.gradle
        fi
      fi
}


# step1 clean
echo 'clean old build'
find . -depth -name "build" | xargs rm -rf
${rootFlutter} clean


# step2 copy so
#echo 'copy so'
#cd ${rootDir}/cache/artifacts/engine
#for arch in android-arm android-arm-profile android-arm-release ; do
#    pushd $arch
#    cp flutter.jar flutter-armeabi-v7a.jar #备份
#    unzip flutter.jar lib/armeabi-v7a/libflutter.so
#    mv lib/armeabi-v7a lib/armeabi
#    zip -d flutter.jar lib/armeabi-v7a/libflutter.so
#    zip flutter.jar lib/armeabi/libflutter.so
#    popd
#done

# step 3 package get
echo 'packages get'
cd ${projectDir} # 回到项目
${rootFlutter} packages get

# step3.1 脚本补充：因为.android是自动编译的，所以内部的配置文件和脚本不可控，所以需要将bak内的脚本自动复制到 .android 内部
echo 'copy bak/config/uploadArchives.gradle to .android/config/... ,    copy bak/gradle.properties to Flutter/gradle.properties'
if [  -d '.android/config/' ]; then
   echo '.android/config 文件夹已存在'
else :
   mkdir .android/config
fi

if [  -f '.android/config/uploadAndroidJar.gradle' ];then
   echo '.android/config/uploadAndroidJar.gradle 已存在'
else :
   cp bak/config/uploadAndroidJar.gradle .android/config/uploadAndroidJar.gradle
fi

if [  -f "android/config/uploadArchives.gradle" ];then
    echo '.android/config/uploadArchives.gradle 已存在'
else :
    cp bak/config/uploadArchives.gradle .android/config/uploadArchives.gradle
fi

cp bak/gradle.properties .android/Flutter/gradle.properties

# step 3.2  脚本补充：同时在Flutter 的gradle中插入引用  apply from: "../uploadArchives.gradle"
echo '在Flutter 的gradle中插入引用  apply from: "../uploadArchives.gradle"'
if [ `grep -c 'uploadArchives.gradle' .android/Flutter/build.gradle` -eq '1' ]; then
    echo "Found!"
else
    echo "not found , 去修改"
    sed -i '' '2i\
    apply from: "../config/uploadArchives.gradle"' .android/Flutter/build.gradle
fi

# setp 3.3 脚本补充：引入fat-aar 相关脚本
# 在 settings.gradle 中 插入 ， 注意 sed 命令换行 在mac下 是 \'$'\n

addFatAArConfig

# step 4.1  build products
echo '编译出四个中间产物 ... '
flutter build aot --suppress-analytics --quiet --target lib/main.dart --target-platform android-arm --output-dir build/app/intermediates/flutter/release  --release
if [ $? -eq 0 ]; then
    echo '编译中间产物 succeed !!!'
else
    echo '编译中间产物出错 !!!'
    exit 1
fi

# step 4.2 copy products
echo '复制中间产物到项目目录下 ... '
mkdir ${projectDir}/.android/Flutter/src/main/assets

cp build/app/intermediates/flutter/release/isolate_snapshot_data ${projectDir}/.android/Flutter/src/main/assets/isolate_snapshot_data
cp build/app/intermediates/flutter/release/isolate_snapshot_instr ${projectDir}/.android/Flutter/src/main/assets/isolate_snapshot_instr
cp build/app/intermediates/flutter/release/vm_snapshot_data ${projectDir}/.android/Flutter/src/main/assets/vm_snapshot_data
cp build/app/intermediates/flutter/release/vm_snapshot_instr ${projectDir}/.android/Flutter/src/main/assets/vm_snapshot_instr

# step 5.1 build assets
echo '编译出assets资源文件文件 ...'
flutter build bundle --suppress-analytics --target lib/main.dart --target-platform android-arm --precompiled --asset-dir  build/app/intermediates/flutter/release/flutter_assets --release
if [ $? -eq 0 ]; then
    echo '编译出assets资源文件文件 succeed !!!'
else
    echo '编译出assets资源文件文件出错......'
    exit 1
fi

# step 5.2 copy assets
echo '复制assets资源文件文件到项目目录 ...'
mkdir ${projectDir}/.android/Flutter/src/main/assets/flutter_assets
cp -r build/app/intermediates/flutter/release/flutter_assets/ ${projectDir}/.android/Flutter/src/main/assets/flutter_assets/
if [ $? -eq 0 ]; then
    echo '复制assets资源文件文件到项目目录 succeed ..'
else
    echo '复制assets资源文件文件到项目目录, 出错 !!!'
    exit 1
fi

# step 6 build aar ，生成 aar ， 然后上传到maven
echo 'build aar'
cd ${projectDir}/.android
gradle clean flutter:assembleRelease uploadArchives --info

if [ $? -eq 0 ]; then
    echo ''
else
    echo 'uploadArchives 出错 !!!'
    delFatAarConfig
    exit 1
fi

# step 7 remove unused files
echo 'remove assets/lib'
cd ${projectDir}/.android/Flutter/src/main/
rm -rf assets
rm -rf lib
delFatAarConfig

echo '<<<<<<<<<<<<<<<<<<<<<<<<<< 结束 >>>>>>>>>>>>>>>>>>>>>>>>>'
echo '打包成功 : yqx-flutter.aar...................！ '
exit