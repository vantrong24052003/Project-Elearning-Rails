# User Prompts Collection

## Mục đích
File này lưu trữ tất cả các prompt đã sử dụng để tham khảo và tái sử dụng. Cursor sẽ đọc file này để hiểu context và yêu cầu của user.

## Cách sử dụng
- Mỗi prompt được đánh số thứ tự
- Cursor sẽ đọc prompt cuối cùng (số lớn nhất) để hiểu yêu cầu hiện tại
- User có thể tham khảo các prompt cũ để tái sử dụng

---

## Prompt #1: Refactor Quiz System

**Ngày tạo:** 2025-01-16
**Mục đích:** Refactor toàn bộ hệ thống quiz với 2 modes riêng biệt
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Tạo được 4 rules cơ bản cho development workflow

```
Use rule 01_get_information, 02_feature_rules, 03_conventions_and_checks, 04_project_structure_rule

Feature: Refactor Quiz System (Practice & Exam modes)
Task 0: Run get_information and return report.

## VẤN ĐỀ HIỆN TẠI:
- Code quiz hiện tại rối và khó maintain
- Không phân biệt rõ practice mode và exam mode
- Anti-cheating chưa hoạt động đúng
- Cần refactor lại từ đầu nhưng giữ nguyên tên file

## YÊU CẦU TÍNH NĂNG:

### Quiz Practice Mode (Luyện tập):
- Chấm điểm tự động sau khi hoàn thành
- Hiển thị giải thích của giảng viên cho từng câu hỏi
- Cho phép xem lại bài làm và học từ sai sót
- Gợi ý nội dung cần học lại dựa trên kết quả

### Quiz Exam Mode (Thi cử):
- Chấm điểm tự động sau khi hoàn thành
- KHÔNG hiển thị giải thích, chỉ hiển thị điểm số
- Hệ thống phát hiện gian lận:
  - Phát hiện chuyển tab/cửa sổ nhiều lần
  - Ghi lại copy/paste, chụp màn hình
  - Cảnh báo dùng nhiều thiết bị/trình duyệt
  - Ghi log chi tiết (thời gian, hành vi, IP, thiết bị)
  - Gửi email cảnh báo giảng viên khi phát hiện bất thường

## RÀNG BUỘC:
- Giữ nguyên tên file hiện tại
- Không comment trong code (trừ frozen_string_literal)
- Phải hỏi rõ mọi điều mơ hồ trước khi code
- Tuân thủ cấu trúc folder theo domain
- Xử lý lỗi và transaction đúng cách
```

---

## Prompt #2: Cập nhật Rules

**Ngày tạo:** 2025-01-16
**Mục đích:** Cải thiện và bổ sung rules hiện có
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Thêm error handling, performance, security vào rules

```
bạn thấy rule có đang thiếu hay dư thừa gì ko ?
```

---

## Prompt #3: Tạo Project Structure Rule

**Ngày tạo:** 2025-01-16
**Mục đích:** Tạo rule về cấu trúc folder và tổ chức code
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Tạo Rule 04_project_structure_rule.md

```
thiếu 1 rules docs nữa , tức là cấu trúc folder code
```

---

## Prompt #4: Tạo User Prompts Collection

**Ngày tạo:** 2025-01-16
**Mục đích:** Tạo file lưu trữ các prompt đã sử dụng
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Tạo file user_prompts.md này

```
tạo ra 1 file md nữa gọi là prompt đầu vào của người dùng , tức cursor sẽ lượt qua file read file ( tìm số cuối cùng mà đọc yêu cầu mục đích là để người dùng tự lưu lại các prompt đã dùng của bản thân
```

---

## Prompt #5: Fix Back Navigation After Submit

**Ngày tạo:** 2025-01-16
**Mục đích:** Chặn việc user có thể quay lại hoặc tiếp tục làm quiz sau khi đã submit
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Implement back navigation prevention logic

```
Use rule 01_get_information, 02_feature_rules, 03_conventions_and_checks, 04_project_structure_rule

Feature: Prevent resuming or editing quiz after submission
Task 0: Run get_information and return report.

## VẤN ĐỀ HIỆN TẠI:
- Sau khi user submit quiz (đã set completed_at), vẫn có thể:
  - Back lại bằng nút trình duyệt
  - Truy cập lại URL start quiz
  - Tiếp tục làm trên cùng quiz_attempt
- Điều này sai logic: attempt đã submit phải readonly.

## YÊU CẦU TÍNH NĂNG:

### Server-side:
- Nếu quiz_attempt có `completed_at` → mọi request update/resume → 403/422 hoặc redirect sang trang kết quả.
- Submit phải set `completed_at` trong transaction, đảm bảo idempotent (ngăn submit lại).
- Khi user request start quiz:
  - Nếu quiz.allow_multiple_attempts → tạo attempt mới
  - Nếu không → redirect sang trang kết quả
- Không tạo migration mới, tận dụng field `completed_at`.

### Client-side:
- Sau khi submit: disable UI, redirect sang trang kết quả (hoặc `history.replaceState` để ngăn back).
- Khi load quiz page: fetch attempt state từ server → nếu completed → redirect sang trang kết quả readonly.
```

---

## Prompt #6: Permanent Back/Retry Handling

**Ngày tạo:** 2025-01-16
**Mục đích:** Chặn vĩnh viễn việc quay lại Quiz sau khi đã submit
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Enhanced back navigation prevention with permanent blocking

### Context
- Hiện tại logic back-block chỉ hoạt động trong **30s**, sau đó user vẫn có thể back vào quiz detail page để thao tác lại.
- Yêu cầu: phải **ngăn chặn vĩnh viễn** đối với Exam, và **reset session chuẩn** đối với Practice.

### Rules

#### Exam
- Sau khi submit: **không bao giờ** quay lại được.
- Redirect mọi request truy cập lại quiz detail/attempt → Quiz List Page + thông báo `"Bạn đã hoàn thành kỳ thi, không thể quay lại."`
- Không dùng timeout (30s), mà dựa trên trạng thái attempt (`completed_at IS NOT NULL`)

#### Practice
- Cho phép làm lại nhiều lần.
- Chỉ tạo attempt mới khi request đến từ **Quiz List Page** với button `"Làm lại"`
- Nếu user cố quay lại bằng back/refresh quiz detail page sau khi nộp:
  - Redirect về Quiz List Page
  - Thông báo `"Vui lòng chọn 'Làm lại' từ danh sách quiz."`

---

## Prompt #7: Hạn chế truy cập quiz ngoài thời gian cho phép

**Ngày tạo:** 2025-01-17
**Mục đích:** Ngăn chặn truy cập quiz ngoài thời gian `start_date` và `end_date`
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Implement server-side time validation với auto-submit cho expired quizzes

### Vấn đề
Hiện tại chỉ ràng buộc hiển thị quiz (`start_date` và `end_date`) ở trang danh sách. Tuy nhiên, người dùng vẫn có thể truy cập trực tiếp bằng URL để vào trang làm bài quiz khi chưa đến `start_date` hoặc đã quá `end_date`.

### Hướng xử lý
- Áp dụng kiểm tra `start_date` và `end_date` ngay tại tầng **controller** hoặc **before_action** khi người dùng truy cập vào `show` hoặc `do_quiz`
- Nếu thời gian truy cập không hợp lệ:
  - Quiz chưa mở: Hiển thị 403 error page
  - Quiz đã đóng: Redirect về trang danh sách + auto submit attempt hiện tại (nếu có)
- Luôn đảm bảo kiểm tra logic này ở backend, không chỉ ở frontend, để tránh bypass bằng URL
- Logging audit trail cho instructor

### Implementation Details
- **Files modified:**
  - `app/controllers/dashboard/quizzes_controller.rb`
  - `app/controllers/dashboard/quiz_attempts_controller.rb`
  - `app/services/dashboard/quiz_service.rb`
- **Key features:**
  - `validate_quiz_time_access` before_action
  - Auto-submit expired attempts with transaction safety
  - Enhanced `can_access_quiz?` method with time validation
  - Proper error handling và user-friendly messages

---


## Prompt #8: Fix Anti-Cheating Logging & Toast Notification

**Ngày tạo:** 2025-01-17
**Mục đích:** Sửa lỗi tính năng bắt gian lận (anti-cheating) không hiển thị toast và không cập nhật database
**Trạng thái:** ✅ Đã hoàn thành
**Kết quả:** Implement smart batching system với real-time toast + intelligent database sync

## VẤN ĐỀ HIỆN TẠI:
- Khi user thực hiện hành vi gian lận (Ctrl+C, Ctrl+V, mở DevTools, right-click, copy/paste, screenshot...):
  - Không có toast thông báo hiển thị
  - Database không tự động cập nhật các counters (ví dụ: copy_paste_count, devtools_open_count, ...)

## YÊU CẦU TÍNH NĂNG:
1. **Toast Notification**
   - Mỗi lần phát hiện hành vi gian lận → hiển thị toast cảnh báo ngay lập tức trên UI.
   - Nội dung toast ngắn gọn, rõ ràng: ví dụ `"Cảnh báo: Bạn vừa mở DevTools!"`

2. **Database Logging**
   - Tự động tăng giá trị counter tương ứng trong bảng `quiz_attempts`
   - Đồng bộ ngay khi hành vi xảy ra, không chờ submit
   - Tránh duplicate logs khi user spam phím tắt

3. **Consistency**
   - Cơ chế detection đồng bộ giữa frontend & backend
   - Toast và DB update phải xảy ra cùng lúc

4. **Audit & Debug**
   - Log thêm hành vi trong `log_actions` (jsonb)
   - Ghi rõ timestamp, action type, attempt_id

### Implementation Details
- **Files modified:**
  - `app/controllers/dashboard/quiz_statuses_controller.rb` - Verified controller bug was already fixed
  - `app/frontend/javascript/controllers/dashboard/quiz_proctor_controller.js` - Added smart batching system
- **Key features:**
  - ✅ **Real-time toast notifications**: Immediate user feedback on cheating actions
  - ✅ **Smart batching sync**: Database sync when 3+ actions detected (threshold-based)
  - ✅ **Emergency sync**: Auto-sync on page unload/hide/visibility change to prevent data loss
  - ✅ **Performance optimized**: Reduces API calls while maintaining data accuracy
  - ✅ **Hybrid strategy**: 30s regular sync + immediate sync on threshold + emergency backup

### Technical Implementation
```javascript
// Smart batching logic
checkSmartBatching() {
  if (this.getTotalPendingCount() >= 3) {  // Threshold = 3 actions
    this.syncBehaviorCounts();  // Immediate sync
    this.resetSyncTimer();      // Reset 30s timer
  }
}

// Emergency sync events
setupEmergencySync() {
  window.addEventListener('beforeunload', () => this.syncBehaviorCounts());
  window.addEventListener('pagehide', () => this.syncBehaviorCounts());
  document.addEventListener('visibilitychange', () => this.syncBehaviorCounts());
}
```

### Result
- **Toast notifications**: ✅ Working (kept existing MessageService styling)
- **Database sync**: ✅ Fixed with intelligent batching strategy
- **Performance**: ✅ Optimized - fewer API calls for normal users, immediate sync for cheaters
- **Data integrity**: ✅ Triple backup (smart batching + regular sync + emergency sync)

## Template cho Prompt mới

**Cách thêm prompt mới:**
1. Copy template dưới đây
2. Điền thông tin và nội dung prompt
3. Đánh số thứ tự tiếp theo

```
## Prompt #[SỐ TIẾP THEO]: [TÊN TÍNH NĂNG]

**Ngày tạo:** YYYY-MM-DD
**Mục đích:** [Mô tả ngắn gọn mục đích]
**Trạng thái:** [🔄 Đang thực hiện / ✅ Đã hoàn thành / ❌ Đã hủy]
**Kết quả:** [Mô tả kết quả đạt được]

```
[NỘI DUNG PROMPT]
```

### Implementation Details (nếu có)
- **Files modified:** [Danh sách files]
- **Key features:** [Các tính năng chính]
- **Notes:** [Ghi chú đặc biệt]
```

---

## Hướng dẫn sử dụng cho Cursor

1. **Đọc prompt cuối cùng:** Tìm prompt có số lớn nhất
2. **Hiểu context:** Đọc các prompt trước đó để hiểu background
3. **Thực hiện yêu cầu:** Làm theo workflow đã định nghĩa
4. **Cập nhật trạng thái:** Báo cáo kết quả và cập nhật trạng thái

## Lưu ý
- Mỗi prompt nên có mục đích rõ ràng
- Ghi chép kết quả để tham khảo sau này
- Sử dụng template để đảm bảo consistency
- Sử dụng emoji status để dễ nhận biết trạng thái
