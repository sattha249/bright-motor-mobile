#!/bin/bash

# สั่ง flutter build apk --debug ก่อน 
echo "Building apk --debug..."
flutter build apk --debug

echo "🚀 กำลังเริ่มต้นการอัปโหลด APK..."
# เช็คก่อนว่ามีไฟล์ APK ที่เพิ่ง Build เสร็จอยู่จริงไหม
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    
    # ส่งไฟล์ขึ้นเซิร์ฟเวอร์ พร้อมเปลี่ยนชื่อเป็น bmt-app.apk (เปลี่ยนชื่อตรงนี้ได้ตามต้องการ)
    scp build/app/outputs/flutter-apk/app-debug.apk brightmotor:~/bmt-apk/bright-motor.apk
    
    echo "✅ อัปโหลดและเขียนทับไฟล์เดิมบน Droplet สำเร็จ!"
else
    echo "❌ ไม่พบไฟล์ APK! กรุณารันคำสั่ง flutter build apk --debug ก่อนครับ"
fi