# کدیار هوشمند (اپ اندروید)

یک اپ اندروید برای نوشتن کد و ساخت فایل با کمک هوش مصنوعی.

## قابلیت‌ها

- رابط کاربری کاملاً فارسی
- پشتیبانی از چند مدل رایگان (مثل Gemini، Groq و ...)
- امکان اضافه کردن **API سفارشی** (هر سرویس جدیدی که API سازگار با OpenAI داشته باشد)
- ساخت و ذخیره فایل
- رابط کاربری زیبا و مدرن

## نحوه اجرا (برای توسعه‌دهندگان)

```bash
git clone https://github.com/aamoozaa20-coder/code-assistant-android.git
cd code-assistant-android
flutter pub get
flutter run
```

## ساخت APK

```bash
flutter build apk --release
```

فایل APK در مسیر زیر ایجاد می‌شود:
`build/app/outputs/flutter-apk/app-release.apk`

## تنظیمات API

در بخش تنظیمات اپ می‌توانید:

1. از مدل‌های پیش‌فرض استفاده کنید
2. یا **API سفارشی** اضافه کنید (آدرس Base URL + API Key + نام مدل)

## مدل‌های پیش‌فرض

- Google Gemini (نیاز به API Key رایگان)
- Groq (نیاز به API Key رایگان)
- هر سرویس OpenAI-compatible دیگر

---

ساخته شده با ❤️ برای استفاده رایگان و قدرتمند
