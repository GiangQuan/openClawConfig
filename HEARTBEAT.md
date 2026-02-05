# HEARTBEAT.md - Nhịp đập kiểm soát

> Protocol 3: Heartbeat - Mô tự báo cáo status định kỳ (30-60 phút)

## 🎯 Mục đích

- Kiểm soát Mô không bị "ngáo" sau chạy liên tục
- Phát hiện sớm nếu Mô lạc lối, lặp lỗi, hoặc im lặng bất thường
- Báo cáo tiến độ task dài hạn cho Quân nắm bắt

## ⏰ Tần suất

- **Mặc định:** Mỗi 30 phút (nếu không có gì mới → `HEARTBEAT_OK`)
- **Khi đang làm task dài:** Report chi tiết mỗi 30-60 phút
- **Khi phát hiện bất thường:** Alert ngay lập tức

## ✅ Checklist chuẩn (mỗi lần heartbeat)

### Luôn kiểm tra:
- [ ] **Cron jobs** - `openclaw cron list` (có job nào pending/failed không?)
- [ ] **Git status** - Có thay đổi cần commit không?
- [ ] **Memory** - Có cần ghi daily notes không?

### Nếu có cấu hình thêm:
- [ ] **Email** - Kiểm tra inbox (nếu có skill email)
- [ ] **Calendar** - Upcoming events trong 24h (nếu có skill calendar)
- [ ] **Notifications** - Mention/social (nếu có)

## 📊 Status Report Format

### Khi KHÔNG có gì đặc biệt:
```
HEARTBEAT_OK
```

### Khi đang làm task dài:
```
🔄 **Task:** [Tên task]
📈 **Tiến độ:** [X]% (bước [Y]/[Z])
⏱️ **Thởi gian:** [duration] phút
🎯 **Dự kiến hoàn thành:** [ETA]
🚨 **Blockers:** [nếu có]
💡 **Confidence:** [0-100]%
```

### Khi phát hiện vấn đề:
```
⚠️ **ALERT:** [mô tả vấn đề]
🔍 **Chi tiết:** [thông tin thêm]
🆘 **Cần hành động:** [đề xuất]
```

## 🚨 Triggers để báo động

Báo cáo NGAY nếu:
- [ ] Mô im lặng > 60 phút khi đang có task active
- [ ] Lặp lại cùng một lỗi > 2 lần
- [ ] Tiêu tốn tokens bất thường (>50k tokens/session)
- [ ] Phát hiện loop vô hạn hoặc không tiến triển

## 📝 Ví dụ thực tế

### Ví dụ 1: Task bình thường
```
HEARTBEAT_OK
Git: clean
Cron: 2 jobs scheduled
Memory: Updated today ✅
```

### Ví dụ 2: Task dài (coding)
```
🔄 **Task:** Refactor database schema
📈 **Tiến độ:** 60% (bước 3/5: đang viết migration scripts)
⏱️ **Thởi gian:** 45 phút
🎯 **Dự kiến hoàn thành:** ~20 phút nữa
🚨 **Blockers:** None
💡 **Confidence:** 90%
```

### Ví dụ 3: Alert
```
⚠️ **ALERT:** Web scraping bị block sau 3 lần thử
🔍 **Chi tiết:** Site đã update anti-bot, cần thay đổi strategy
🆘 **Cần hành động:** Quân xác nhận có nên thử proxy hoặc skip task?
```

## 🔧 Commands tham khảo

```bash
# Kiểm tra cron
openclaw cron list

# Kiểm tra git
git status

# Kiểm tra system resources
openclaw status
```

## 🎛️ Điều chỉnh

Nếu Quân thấy 30 phút quá thường xuyên hoặc quá thưa:
- Điều chỉnh trong OpenClaw config (gateway heartbeat interval)
- Hoặc thêm cron job riêng cho task-specific heartbeat

---

*Cập nhật: 2026-02-05 | Protocol 3 implemented*
