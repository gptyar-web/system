# نصب مستقل مدرسه در schema اختصاصی Supabase

برای استقرار یک مدرسهٔ جدید و جدا از برنامه‌ای که در schema `public` اجرا می‌شود، تولیدکنندهٔ `supabase/install-school.mjs` فایل SQL تراکنشی و فهرست SHA-256 منابع بررسی‌شده را تولید می‌کند.

## اجرای ایمن
1. از پایگاه داده و Auth پروژهٔ مقصد نسخهٔ پشتیبان قابل‌بازیابی تهیه کنید.
2. با Node.js دستور `node supabase/install-school.mjs --out /tmp/school-install-review` را اجرا کنید.
3. خروجی `install.sql` و `manifest.json` را بررسی و ابتدا روی محیط آزمایشی اجرا کنید.
4. دسترسی معلم، دانش‌آموز و مدیر، MFA مدیر، RLS، Storage و عملیات روزمره مدرسه را آزمایش کنید؛ سپس فقط بر اساس نتیجه آزمایش، نصب تولید را اجرا کنید.
5. در صورت استقرار روی schema `school`، تنظیمات `SYSTEM_DB_SCHEMA=school` برای Edge Function و `SUPABASE_DB_SCHEMA=school`، `ASSIGNMENT_BUCKET=school-assignment-files` برای کلاینت لازم است.

نصب‌کننده برای انتقال کاربران یا داده‌های یک پروژهٔ موجود به پروژهٔ دیگر طراحی نشده است. کنترل مدیر با `assert_manager_session` و Supabase Auth انجام می‌شود؛ نصب مستقل، OAuth کلاینت خارجی یا schema اختصاصی ChatGPT ایجاد نمی‌کند.

**برای حذف اتصال ChatGPT قبلی از پروژهٔ موجود، به [راهنمای جمع‌آوری](DECOMMISSION.md) و Migration جداگانه مراجعه کنید.** نصب مدرسهٔ جدید، endpointهای قدیمی Supabase را حذف نخواهد کرد.
