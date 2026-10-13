# Delivery status — 2026-10-10

کد روی شاخهٔ `feature/secure-chatgpt-oauth` در GitHub است: [PR #12](https://github.com/mozdbaranarshiya/system/pull/12). با دستور جدید مالک برای تکمیل همهٔ کارها، SQL افزایشی روی پروژهٔ واقعی `efibfevyiepkwpnobaro` نصب و هر سه Backend جدید مستقر شدند. شاخه هنوز به `main` ادغام نشده و انتشار رابط در حال تکمیل است. مدیر، حساب‌ها و داده‌های موجود حفظ می‌شوند؛ اتصال واقعی ChatGPT هنوز به Client و callback پلتفرم نیاز دارد.

[دانلود ZIP موقت](https://github.com/mozdbaranarshiya/system/releases/download/system-school-plugin-20261010-2019ae0/system-school-plugin-20261010.zip) و [Checksum](https://github.com/mozdbaranarshiya/system/releases/download/system-school-plugin-20261010-2019ae0/system-school-plugin-20261010.zip.sha256) منتشر و با دانلود عمومی دوباره بررسی شدند. آرشیو از Commit `2019ae002bff477335de1336dae32a05b759af58` است؛ خود Git tag نیز با همین Commit تطبیق داده شد. شش فایل، ۱۳٬۵۵۹ بایت و SHA-256 `d22dd4e6ba7063ca58d81d8e0b5bfe26292f965d2469d5a81e4e63e41b780345` دارد. ZIP در Git history قرار نگرفته و تا درخواست بعدی مالک حذف نمی‌شود.

## Architecture implemented

معماری موجود HTML/CSS/JavaScript، Supabase Auth/Postgres/RLS و Deno Edge حفظ شد. Provider افزایشی OAuth-compatible به Login و TOTP بومی متصل است؛ Framework، مدل User یا سیستم Permission موازی ندارد. نقش‌های واقعی `student`، `teacher` و `manager` و رابطه‌های `class_students` و `teacher_assignments` منبع مجوزند. Native OAuth پروژه هنگام بررسی غیرفعال بود؛ Adapterهای قبلی برای کنترل‌های موردنیاز و Opaque Token مناسب نیستند و بدون تغییر حفظ شدند. شرح کامل در [OAUTH.md](OAUTH.md).

## Files added

34 فایل جدید:

- [.env.example](../.env.example)
- [.github/workflows/school-plugin-release.yml](../.github/workflows/school-plugin-release.yml)
- [docs/CHATGPT_SETUP.md](../docs/CHATGPT_SETUP.md)
- [docs/DELIVERY_STATUS.md](../docs/DELIVERY_STATUS.md)
- [docs/MIGRATION.md](../docs/MIGRATION.md)
- [docs/OAUTH.md](../docs/OAUTH.md)
- [docs/chatgpt-openapi.yaml](../docs/chatgpt-openapi.yaml)
- [js/oauth.js](../js/oauth.js)
- [plugins/package_school.py](../plugins/package_school.py)
- [plugins/system-school/.codex-plugin/plugin.json](../plugins/system-school/.codex-plugin/plugin.json)
- [plugins/system-school/README.md](../plugins/system-school/README.md)
- [plugins/system-school/references/CHATGPT_SETUP.md](../plugins/system-school/references/CHATGPT_SETUP.md)
- [plugins/system-school/references/chatgpt-openapi.yaml](../plugins/system-school/references/chatgpt-openapi.yaml)
- [plugins/system-school/skills/system-school/SKILL.md](../plugins/system-school/skills/system-school/SKILL.md)
- [plugins/system-school/skills/system-school/scripts/school_api.py](../plugins/system-school/skills/system-school/scripts/school_api.py)
- [supabase/config.toml](../supabase/config.toml)
- [supabase/functions/oauth-connector/handler.ts](../supabase/functions/oauth-connector/handler.ts)
- [supabase/functions/oauth-connector/index.ts](../supabase/functions/oauth-connector/index.ts)
- [supabase/install-school.mjs](../supabase/install-school.mjs)
- [supabase/migrations/20261007_oauth_connector.sql](../supabase/migrations/20261007_oauth_connector.sql)
- [supabase/migrations/20261009_manager_session_guard.sql](../supabase/migrations/20261009_manager_session_guard.sql)
- [supabase/prepare-source-oauth.mjs](../supabase/prepare-source-oauth.mjs)
- [supabase/source-oauth-setup.sql](../supabase/source-oauth-setup.sql)
- [tests/admin-user.mjs](../tests/admin-user.mjs)
- [tests/auth-live.mjs](../tests/auth-live.mjs)
- [tests/oauth-browser.mjs](../tests/oauth-browser.mjs)
- [tests/oauth-concurrency.mjs](../tests/oauth-concurrency.mjs)
- [tests/oauth-database.mjs](../tests/oauth-database.mjs)
- [tests/oauth-edge.mjs](../tests/oauth-edge.mjs)
- [tests/oauth-integration.mjs](../tests/oauth-integration.mjs)
- [tests/oauth-ui.mjs](../tests/oauth-ui.mjs)
- [tests/plugin-package.mjs](../tests/plugin-package.mjs)
- [tests/schema-isolation.mjs](../tests/schema-isolation.mjs)
- [tests/source-oauth-setup.mjs](../tests/source-oauth-setup.mjs)

## Files modified

18 فایل موجود تغییر کرده:

- [.gitignore](../.gitignore)
- [README.md](../README.md)
- [app.js](../app.js)
- [config.js](../config.js)
- [index.html](../index.html)
- [js/auth.js](../js/auth.js)
- [package.json](../package.json)
- [styles-v7.css](../styles-v7.css)
- [supabase/functions/account-security/index.ts](../supabase/functions/account-security/index.ts)
- [supabase/functions/admin-user/index.ts](../supabase/functions/admin-user/index.ts)
- [tests/browser.mjs](../tests/browser.mjs)
- [tests/database-setup.mjs](../tests/database-setup.mjs)
- [tests/edge.mjs](../tests/edge.mjs)
- [tests/fixtures.mjs](../tests/fixtures.mjs)
- [tests/migrations-check.mjs](../tests/migrations-check.mjs)
- [tests/syntax.mjs](../tests/syntax.mjs)
- [tests/unit.mjs](../tests/unit.mjs)
- [tests/xlsx.mjs](../tests/xlsx.mjs)

## Database changes

SQL افزایشی [source-oauth-setup.sql](../supabase/source-oauth-setup.sql) با SHA-256 `4881d262153993be15246d64de38f0dbb1500e821ef80e1d10e5150487854ca7` روی مدرسهٔ واقعی نصب شد؛ دوباره اجرا نشود. هفت جدول خصوصی با RLS، RPCهای فقط-service، لغو/cleanup/Audit، کنترل Session/عامل جاری مدیر و ACL اصلاح‌شدهٔ guard برقرارند. مقایسهٔ قبل/بعد، دادهٔ تمام ۵۲ جدول مدرسه، fingerprint شش حساب Auth و یک عامل MFA، بدنهٔ تابع‌های قبلی و ساختار/ACL/RLS/Policyهای قبلی را تأیید کرد. Job ساعتی OAuth و Job پانزده‌دقیقه‌ای یادآوری قبلی فعال‌اند. بازیابی خصوصی داده‌ها/تعاریف مدرسه و کد قبلی دو تابع مدیریتی با مجوز ۶۰۰ خارج Git ذخیره شده است؛ Auth secret خام export نشد. پروژه Backup مدیریت‌شده یا PITR فعال ندارد؛ این snapshot جایگزین Backup کامل Auth نیست. نصب جداگانهٔ آماده‌باش از این مرحله مستقل است.

## OAuth endpoints

Base مستقر: `https://efibfevyiepkwpnobaro.supabase.co/functions/v1/oauth-connector`؛ تابع OAuth نسخهٔ ۱، مدیریت کاربران نسخهٔ ۸ و امنیت حساب نسخهٔ ۴ `ACTIVE` هستند. ۲۷ بررسی واقعی HTTP امنیت/رد درخواست موفق است؛ ورود حساب واقعی و callback ChatGPT آزموده نشده‌اند.

| مسیر | کاربرد |
| --- | --- |
| `GET /oauth/authorize` | اعتبارسنجی درخواست و هدایت به Login/Session/MFA/Consent سایت |
| `POST /oauth/prepare` و `/oauth/decision` | Context یک‌بارمصرف Consent، اجازه/لغو با هویت بومی |
| `POST /oauth/token` | Authorization Code exchange و `grant_type=refresh_token` |
| `POST /oauth/revoke` | لغو استاندارد Token |
| `GET /api/me` | شناسه و نام نمایشی حداقلی کاربر متصل |
| `GET /api/classes`, `/api/grades`, `/api/assignments` | دادهٔ مجاز با کنترل Scope، مجوز فعلی و Resource |
| `POST /account/connections`, `/account/disconnect` | اتصال‌های حساب و قطع اتصال |
| `POST /account/admin/clients` | مدیریت Client با مجوز مدیر و MFA تازه |

این Provider OIDC نیست و JWKS یا ID Token تولید نمی‌کند. MCP جدید نیز پیاده‌سازی نشده است.

## Scopes

`profile.read`, `classes.read`, `grades.read`, `assignments.read`. هیچ Scope نوشتن یا مدیریتی به ChatGPT داده نشده است. Scope جایگزین مجوز داخلی و Ownership نیست.

## MFA behavior

مدیر موجود از عامل TOTP بومی خود استفاده می‌کند. بدون عامل تأییدشده و Session جاری AAL2 و TOTP در ده دقیقهٔ گذشته، Client/Consent/Code OAuth مدیر رد می‌شود. Enrollment در صورت نبود عامل و Step-up برای Context قدیمی در همان UI انجام می‌شود. Session/Factor از سرور بررسی می‌شوند؛ Flag ارسالی Client اعتبار ندارد. کاربر عادی تابع سیاست فعلی مدرسه است. رمز و OTP فقط در Backend/Auth خود مدرسه پردازش می‌شوند.

## Token strategy

Opaque Token برای کنترل DB و لغو فوری انتخاب شده است. Code کوتاه‌عمر ۱۲۰ ثانیه و یک‌بارمصرف، Access Token پانزده دقیقه و Refresh Token سی روز با انقضای مطلق، Rotation و reuse detection دارد. Secret/Code/Token خام در جدول ذخیره نمی‌شود؛ Hash امن ذخیره می‌شود. Grant به User، Client، Scope و برای مدیر عامل MFA معتبر متصل است. Disconnect خانواده‌های Access/Refresh و Contextهای معلق اتصال را لغو می‌کند.

## Security protections

Exact callback registration، S256 PKCE، Client authentication، state حفظ‌شده، Origin و JSON/nonce برای Consent، کنترل فعال‌بودن حساب/رمز اولیه، MFA سمت سرور، Rate limit، خطاهای عمومی، Audit بدون Credential، Least privilege و حفاظت IDOR اجرا شده‌اند. API جدید Role/Permission ارسالی Client را قبول نمی‌کند. Secrets فقط Runtime امن هستند. ZIP فقط فایل‌های عمومی allowlist دارد؛ Redirect، Host دلخواه، Credential در CLI و خطاهای خام در Helper رد می‌شوند. بسته App ID ساختگی یا REST به‌جای MCP ندارد.

## Tests added

SQL واقعی با PGlite، مرزهای HTTP/Auth، Consent/Connected Apps، Scope/Ownership، PKCE، Code single-use، Expiry، Refresh/Reuse، revoke، MFA/session، نصب مستقل و SQL افزایشی/rollback، Chromium، هم‌زمانی PostgreSQL و Password/TOTP با GoTrue محلی پوشش داده شده‌اند. آزمون بسته، محدودسازی HTTPS، نبود Credential و سلامت ZIP نیز اضافه شده است. فایل‌های کامل در فهرست بالا و محدودیت هر suite در [OAUTH.md](OAUTH.md) هستند.

## Tests passed

| بررسی | نتیجه و محدودیت |
| --- | --- |
| suite اصلی npm در همین ادامهٔ کار | موفق: ۶۳ DB امنیت، ۲۲ امنیت حساب، ۳۲ مدیریت، ۷۳ UI، ۴۰ جداسازی و ۲۲۱ OAuth؛ واحد/Migration نیز موفق. Auth شبکه در suiteهای HTTP/UI mock است |
| `test:source-setup` | ۲۲ بررسی SQL واقعی؛ حفظ داده/Auth، ACL، MFA، collision و rollback واقعی |
| `test:plugin` | ۵۰ مرز Helper + ۸ بسته/CLI + ۱۱ سلامت/ایمنی ZIP؛ موفق محلی و در GitHub Actions، بدون درخواست Production |
| `check` | Syntax JavaScript/Edge موفق؛ frontend مرحلهٔ build مستقل ندارد |
| Chromium با config فعلی | ۶ OAuth و ۵۶ رابط اصلی موفق با `/usr/bin/chromium`؛ DB آزمایشی واقعی، HTTP/Auth mock، بدون اتصال به مدرسهٔ Production |
| Excel از دامنهٔ جایگزین | فایل واقعی، فارسی، RTL، کد ملی رشته‌ای با صفر آغازین و نمرهٔ صفر؛ SHA رسمی حفظ شد |
| تست‌های تخصصی قبلاً اجراشده در این کار | سه Deno type check، ۲۶ هم‌زمانی PostgreSQL واقعی و ۱۸ Password/TOTP واقعی GoTrue محلی موفق؛ در این مرحله بدون تغییر کد آنها تکرار نشدند |
| انتشار ZIP | GitHub Actions run `38064167509` موفق؛ دانلود عمومی، checksum، محتوا، CRC و Git tag بررسی شدند |
| Backend واقعی مدرسه | ۲۷ بررسی رد Token/Client/Grant نامعتبر، Origin/CORS/Header، API محافظت‌شده، RPCهای فقط-service و Schema خصوصی؛ Client/Grant/Access/Refresh واقعی صفر و ثبت Client بدون MFA انجام نشد |

Playwright در اجرای اولیه دنبال Browser cache غایب بود؛ با Chromium نصب‌شده و مسیر مستند محیط، هر دو suite کامل موفق شدند. نصب جدید یا غیرفعال‌کردن Assertion لازم نشد.

## Remaining risks

SQL و Backend روی مدرسهٔ واقعی آماده‌اند؛ انتشار `main`/سایت در حال تکمیل است. callback واقعی و آزمون نهایی دانش‌آموز/دبیر/مدیر در ChatGPT باقی مانده‌اند. Upload ZIP و تزریق امن OAuth Token در ChatGPT Plugins تأیید نشده‌اند؛ این ZIP بستهٔ Integration/Setup است و broker اتصال خودکار/refresh ندارد. مسیر مستند قابل‌تنظیم GPT Actions است. گواهی conformance و Audit امنیتی بیرونی برای Provider اختصاصی انجام نشده است. Backup کامل مدیریت‌شده/PITR پروژه نیز در بررسی فعال نبود.

یافته‌های مرتبط موجود جداگانه: مانع اجرای guard برای `service_role` با نصب SQL رفع شد و بدنهٔ guard حفظ شده است. Adapterهای ChatGPT قدیمی Scope واقعی Token و عامل/Session جاری مدیر را مانند Provider جدید کنترل نمی‌کنند؛ قبل از فعال‌کردن مسیر بومی به اصلاح و آزمون مستقل نیاز دارند. سه تابع قدیمی حفظ شدند و fingerprint بستهٔ کد آنها با قبل برابر است؛ تغییر شمارهٔ نسخهٔ آنها نتیجهٔ اعمال تنظیمات Runtime است. RLS گستردهٔ classes و بعضی مجوزهای تاریخی تکلیف با شرط Resource اضافی در API جدید محدود شدند؛ hardening کل Data API قدیمی جداست. GitHub Pages Header سفارشی `frame-ancestors` فراهم نمی‌کند؛ CSP meta این حفاظت را جایگزین نمی‌کند. جزئیات در بخش Security concerns در [OAUTH.md](OAUTH.md).

## Production configuration required

نصب همین پروژه انجام شده؛ SQL آماده دوباره اجرا نشود. نتیجهٔ تأییدشده: `oauth_tables=7`, `oauth_rls_tables=7`, `service_guard_allowed=true`, `manager_session_guard_ready=true`. سه تابع `oauth-connector`, `admin-user`, `account-security` با Project ref صریح مستقر شدند و سایر تابع‌ها/کاربران/داده‌ها حفظ‌اند. مرحلهٔ جاری انتشار رابط است؛ سپس Client واقعی با MFA مدیر ثبت می‌شود.

`SYSTEM_DB_SCHEMA=public`، `OAUTH_SITE_URL=https://mozdbaranarshiya.github.io/system/index.html`، `OAUTH_ALLOWED_ORIGINS=https://mozdbaranarshiya.github.io`، `OAUTH_ALLOW_LOCAL_HTTP=false` و کلیدهای server-only فراهم‌شده توسط Runtime همان پروژه لازم‌اند. Schemaهای خصوصی expose نشوند و cleanup، Audit/Backup و Headerها طبق [MIGRATION.md](MIGRATION.md) تنظیم شوند. هیچ Secret در ZIP یا مرورگر قرار نمی‌گیرد. تنظیمات startup محیط توسعه نیز در Draft ذخیره شده‌اند؛ Save/Publish محیط با انتشار سایت و SQL یکسان نیست.

## How to connect ChatGPT

پس از SQL و استقرار، مدیر موجود با MFA تازه در «برنامه‌های متصل» Client confidential را برای callback دقیق GPT Builder ثبت کند. در GPT Builder → Actions، [OpenAPI](chatgpt-openapi.yaml) و OAuth Authorization/Token URL بالا و Client ID/Secret امن تنظیم شوند. کاربر Connect → Login یا Session موجود → MFA در صورت نیاز → Consent را طی می‌کند؛ ChatGPT فقط Token همان کاربر را می‌گیرد. قطع اتصال از همان بخش سایت انجام می‌شود.

برای درخواست Upload فعلی، [ZIP](https://github.com/mozdbaranarshiya/system/releases/download/system-school-plugin-20261010-2019ae0/system-school-plugin-20261010.zip) را در Plugins → Upload plugin انتخاب کنید. پذیرش احتمالی آرشیو اثبات اتصال OAuth نیست؛ بدون پشتیبانی صریح Runtime برای binding امن Token، بسته باید درخواست داده را متوقف و راهنمای Actions بدهد. Password/OTP/Token را در چت وارد نکنید. [راهنمای کامل](CHATGPT_SETUP.md).
