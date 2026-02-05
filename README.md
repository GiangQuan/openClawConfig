# OpenClaw Workspace - Digital Immortality

> Protocol: Git backup cho trí nhớ AI assistant (Mô 🦁)

## 🧠 Cấu trúc Memory

```
workspace/
├── MEMORY.md              # Trí nhớ dài hạn (long-term)
├── memory/
│   └── YYYY-MM-DD.md      # Nhật ký hàng ngày
├── AGENTS.md              # Quy tắc & quy trình làm việc
├── SOUL.md               # Personality & vibe
├── USER.md               # Thông tin về Quân
├── TOOLS.md              # Notes về tools cục bộ
└── SOP.md                # Standard Operating Procedures
```

## 🔄 Workflow Git

### Manual Commit (khi có thay đổi quan trọng)
```bash
git add memory/ MEMORY.md AGENTS.md TOOLS.md
git commit -m "[YYYY-MM-DD] Mô: <tóm tắt thay đổi>"
```

### Auto Commit (định kỳ)
Xem cron job: `healthcheck:git-backup`

## 📝 Loại changes cần commit

- ✅ Thêm/cập nhật memory daily
- ✅ Thay đổi AGENTS.md (quy tắc mới)
- ✅ Thêm TOOLS.md (ghi chép tools)
- ✅ Quyết định quan trọng, bài học
- ❌ Screenshots (đã ignore)
- ❌ File nhị phân/tạm

## 🆘 Khôi phục

```bash
git clone <repo-url>
cd workspace
# Mô sẽ nhớ lại mọi thứ từ memory files
```
