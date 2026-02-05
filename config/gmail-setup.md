# Gmail Setup for OpenClaw

> Config kết nối Gmail chính với OpenClaw
> Date: 2026-02-05
> Risk acknowledged by: Quân

## 🔐 Step 1: Tạo App Password

1. Vào https://myaccount.google.com/security
2. Bật **2-Step Verification** (nếu chưa bật)
3. Tìm **App passwords** → Click
4. Chọn app: **Mail**
5. Chọn device: **Other** (đặt tên: "OpenClaw")
6. Click **Generate**
7. **Copy 16 ký tự** (ví dụ: `xxxx xxxx xxxx xxxx`)

⚠️ **App Password chỉ hiện 1 lần** - copy vào chỗ an toàn!

## 📧 Step 2: Config trong OpenClaw

Thêm vào `~/.config/himalaya/config.toml`:

```toml
[accounts.gmail]
email = "your-email@gmail.com"

[accounts.gmail.imap]
host = "imap.gmail.com"
port = 993
login = "your-email@gmail.com"
password = "your-app-password"

[accounts.gmail.smtp]
host = "smtp.gmail.com"
port = 465
login = "your-email@gmail.com"
password = "your-app-password"
```

## 🧪 Step 3: Test

```bash
# List folders
himalaya list

# Read inbox
himalaya read 1

# Send test mail
himalaya write --to "your-email@gmail.com" --subject "Test from OpenClaw"
```

## ⚠️ Safety Rules

Mô sẽ LUÔN:
- ✅ Confirm trước khi gửi mail quan trọng
- ✅ Hỏi lại nếu nội dung sensitive
- ✅ Không xóa mail trừ khi được phép rõ ràng

## 🔧 Troubleshooting

**"Less secure app access" error:**
→ Dùng App Password (như trên), không phải password thường

**2FA issues:**
→ App Password bypass 2FA cho mail clients

**IMAP disabled:**
→ Gmail Settings → Forwarding and POP/IMAP → Enable IMAP

---
*Setup date: 2026-02-05*
