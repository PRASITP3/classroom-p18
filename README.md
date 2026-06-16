# 🌻 Classroom P.1/8

โปรเจกต์ห้อง ป.1/8 (ครูมาแตม) — รวมเครื่องมือสำหรับห้องเรียนไว้ที่เดียว
เป็นเว็บ static (HTML ล้วน ไม่มี build step) เปิดไฟล์ได้เลย หรือ deploy บน Vercel

## โครงสร้าง

```
classroom-p18/
├─ index.html            หน้าหลัก (Hub) → เลือก ทะเบียน / ติวเด็ก
├─ registry.html         แอปทะเบียนนักเรียน-ผู้ปกครอง-ครู (เก็บข้อมูลใน Supabase)
├─ practice/
│   ├─ index.html        คลังเกมติว (render การ์ดจากอาเรย์ GAMES)
│   └─ body-senses.html  เกม Body & Senses (ฟัง/เลือกคำ/จับคู่)
└─ README.md
```

## ทะเบียน (registry.html)
- Backend: Supabase project `qznafcgkzlcfjyyrdqhk`
- ตาราง: `registry_students`, `registry_parents`, `registry_teachers` + storage bucket `registry-photos`
- เลขที่นักเรียน (`number`) พิมพ์เอง — **ยังไม่มีระบบกันเลขซ้ำ** (ดู TODO)

## ติวเด็ก (practice/)
ศูนย์รวมเกม/แบบทดสอบ ออกแบบให้เพิ่มเกมใหม่ได้ง่าย

**เพิ่มเกมใหม่ 2 ขั้น:**
1. สร้างไฟล์ `practice/ชื่อเกม.html` (เกม standalone 1 ไฟล์)
2. เพิ่ม 1 รายการในอาเรย์ `GAMES` ใน `practice/index.html`:
   ```js
   { title:'ชื่อเกม', desc:'คำอธิบาย', subject:'English',
     emoji:'🧩', color:'linear-gradient(135deg,#..,#..)',
     file:'ชื่อเกม.html', ready:true }
   ```
   ตั้ง `ready:false` เพื่อแสดงเป็น "เร็วๆ นี้" ก่อนสร้างไฟล์เสร็จ

## Deploy
Static HTML hosted on Vercel — root = `index.html` (Hub)

## TODO / พัฒนาต่อ
- [ ] registry: เตือน/กันเลขที่นักเรียนซ้ำตอนกรอก
- [ ] practice: เกม Numbers 1–20, ABC Phonics (มี placeholder แล้ว)
- [ ] (ออปชัน) ผูกคะแนนเกมกับนักเรียนแต่ละคนใน Supabase
