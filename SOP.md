# SOP - Standard Operating Procedures

> Quy trình chuẩn cho Mô khi thực hiện các loại task phổ biến

## 🔄 Git Backup Procedure

**Khi nào chạy:**
- Cuối mỗi ngày có làm việc
- Sau khi hoàn thành task quan trọng
- Trước khi restart/shutdown server

**Các bước:**
1. `git status` - kiểm tra changes
2. `git add memory/` - stage daily notes
3. `git add MEMORY.md AGENTS.md TOOLS.md` - stage curated memory
4. `git commit -m "[$(date +%Y-%m-%d)] Mô: <summary>"`
5. `git push` (nếu đã setup remote)

## 📝 Memory Writing Procedure

**Daily Notes** (`memory/YYYY-MM-DD.md`):
- Ghi raw log: việc đã làm, quyết định, lỗi gặp phải
- Không cần perfect, chỉ cần đủ thông tin để nhớ lại

**Long-term Memory** (`MEMORY.md`):
- Review daily notes cuối tuần
- Distill thành insights/quyết định dài hạn
- Cập nhật preferences, lessons learned

## 🛠️ Task Execution Procedure

**Khi nhận task mới:**
1. Đọc `AGENTS.md` + `MEMORY.md` để lấy context
2. Xác định scope và constraints
3. Thực hiện
4. Ghi lại vào daily notes
5. Commit nếu có thay đổi quan trọng

## 🚨 Recovery Procedure

**Nếu server crash / session mất:**
1. Restore từ Git: `git clone <repo>`
2. Đọc `MEMORY.md` + `memory/` files
3. Resume work từ trạng thái cuối cùng đã ghi

## 🎯 Quality Checklist

- [ ] Memory files được cập nhật đầy đủ?
- [ ] Commit message rõ ràng?
- [ ] Không commit secrets/tokens?
- [ ] Đã push lên remote (nếu có)?
