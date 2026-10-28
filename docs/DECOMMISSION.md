# راهنمای جمع‌آوری اتصال ChatGPT

این مخزن دیگر کد اتصال ChatGPT، صفحهٔ اجازهٔ اتصال، افزونه، endpoint اختصاصی و بستهٔ انتشار آن را ارائه نمی‌کند. کنترل MFA مدیر، مدیریت کاربران و ورود Supabase Auth حفظ می‌شوند.

## روش دریافت گزارش بدون اطلاعات محرمانه

فایل [گزارش فقط‌خواندنی](../supabase/diagnostics/chatgpt-metadata-audit.sql) را جداگانه در SQL Editor هر یک از پروژه‌های اصلی و آماده‌باش اجرا کنید. فقط ستون `safe_report` را با برچسب پروژه ارسال کنید. این گزارش نام schema، توابع، Trigger و Policy را می‌خواند و ردیف اطلاعات کاربران، توکن و کلید را نمایش نمی‌دهد.

برای مشاهده نام توابع Edge، پس از اجرای `supabase login` روی دستگاه شخصی خودتان، دستور `bash scripts/chatgpt-edge-functions.sh audit main` و برای پروژه آماده‌باش `bash scripts/chatgpt-edge-functions.sh audit standby` را اجرا کنید. اجرای `remove` فقط بعد از تأیید مقصد، نسخه پشتیبان و بازبینی وابستگی‌ها مجاز است؛ هر تابع تأیید جداگانه لازم دارد.

## عملیات لازم روی سرویس زنده

طبق سوابق مخزن، پروژهٔ اصلی `efibfevyiepkwpnobaro` قبلاً دارای schema اختصاصی `system_oauth` و Edge Function به نام `oauth-connector` بوده است. دو Edge Function قدیمی `chatgpt-api` و `chatgpt-mcp` نیز گزارش شده‌اند. پروژهٔ آماده‌باش `pukanizbahswrupscfmg` احتمالاً دارای schema `school_oauth` و Job مستقل است. وضعیت واقعی فعلی از اتصال GitHub قابل تأیید نیست.

1. **پشتیبان‌گیری:** قبل از حذف پایگاه داده، Backup قابل‌بازیابی از دیتابیس و Auth تهیه و در محیط جداگانه restore کنید. Migration تمام Clientها، Grantها و هش توکن‌های مربوط به schema قبلی را پاک می‌کند.
2. **دیتابیس اصلی:** migration `supabase/migrations/20261028_remove_chatgpt_connector.sql` را ابتدا در نسخهٔ آزمایشی، سپس در SQL Editor پروژهٔ اصلی اجرا کنید. این فایل Cron، Trigger، RPCها و schema اختصاصی را جمع‌آوری می‌کند، اما `assert_manager_session` را حفظ می‌کند.
3. **Edge Functions:** در پنل Supabase، پس از بررسی وابستگی‌ها، `oauth-connector` و توابع قدیمی `chatgpt-api` و `chatgpt-mcp` را حذف کنید. `admin-user` و `account-security` باید باقی بمانند. برای پاک‌سازی دسته‌جمعی Functions از `--prune` استفاده نکنید.
4. **Auth و تنظیمات:** OAuth Clientها، Redirect URLها، Hooks و تنظیمات مخصوص اتصال حذف‌شده را شناسایی و غیرفعال کنید. تغییرات عمومی Auth، MFA و `pgrst.db_pre_request` را بدون بررسی اثر بر برنامه‌های دیگر انجام ندهید.
5. **پروژهٔ آماده‌باش:** اگر schema `school_oauth` وجود دارد، روی همان پروژه با بررسی وابستگی‌ها، Job `school-oauth-cleanup`، RPCهای وابسته، Triggerها و schema را جداگانه حذف کنید. Migration موجود فقط برای `system_oauth` پروژهٔ اصلی است.
6. **پلتفرم‌های خارجی:** اپلیکیشن یا Plugin آپلودشده، GPT Actions، OAuth Client Secret و توکن‌های مربوط را در حساب مقصد حذف/باطل کنید؛ GitHub Release و شاخه‌های قدیمی نیز ممکن است همچنان نسخهٔ قابل‌دریافت بسته را منتشر کنند.

## کنترل نهایی

- هیچ صفحهٔ اتصال، لینک Consent یا SDK اختصاصی در سایت منتشرشده باقی نباشد.
- endpointهای قدیمی `chatgpt-api`، `chatgpt-mcp` و `oauth-connector` پاسخ عملیاتی ندهند.
- `system_oauth`، RPCهای `oauth_operation`، `oauth_api` و Job قدیمی حذف شده باشند.
- ورود عادی، MFA مدیر، تغییر رمز، RLS و دسترسی آموزشی پس از انتشار بدون اختلال کار کنند.

GitHub به‌تنهایی مجوز اجرای SQL، حذف Edge Function یا غیرفعال‌سازی افزونه نصب‌شده در حساب ChatGPT را نمی‌دهد. **تا انجام این اقدامات خارج از مخزن، قطع کامل اتصال در سرویس عملیاتی تأیید نشده است.**

## وضعیت اجرای واقعی — ۲۰۲۶-۱۰-۲۸

با اتصال مدیریت Supabase روی پروژه اصلی `efibfevyiepkwpnobaro`، جدول‌های `system_oauth`، RPCها و Job `system-oauth-cleanup` با Migration `retire_legacy_chatgpt_oauth_20261028` حذف شدند. تعداد Clientهای بومی Auth و `oauth_connected_apps` پیش از حذف صفر بود. Migration `retire_native_chatgpt_records_keep_auth_hook_safe_20261028` نیز جدول‌های `public.oauth_connected_apps` و `system_private.chatgpt_oauth_config` را حذف کرد. سه Edge Function با نام‌های `chatgpt-mcp`، `chatgpt-api` و `oauth-connector` به handler پاسخ‌دهنده 410 Gone تغییر یافتند و قابلیت اصلی آن‌ها غیرفعال است؛ خود نام‌های Functions هنوز در پنل وجود دارند چون ابزار فعلی حذف مستقیم ندارد. تابع `chatgpt_access_token_hook` برای جلوگیری از خرابی احتمالی Auth فعلاً به identity/pass-through تبدیل شده و حذف فیزیکی نهایی آن وابسته به برداشتن ارجاع تنظیمات Auth است. محافظ‌های `oauth_no_direct_access`، `oauth_no_direct_storage`، `oauth_postgrest_guard` و `assert_manager_session` عمداً حفظ شدند. ایندکس دقیقاً تکراری `idx_group_score_archives_group` نیز حذف شد. اتصال افزونه‌ای در حساب ChatGPT یا انتشار Releaseهای قبلی از مسیر Supabase قابل حذف یا تأیید نیست.

**هشدار:** تکرار Migrationهای حذف روی محیطی که قبلاً پاک‌سازی شده لازم نیست. قبل از هر تغییری در Hook/Auth یا RLS، تنظیمات زنده، وابستگی‌ها و ورود مدیر را مستقل بررسی کنید.
