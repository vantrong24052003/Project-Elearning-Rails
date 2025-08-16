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

## CÂU HỎI CẦN LÀM RÕ:
1. Practice mode hiển thị giải thích ngay sau mỗi câu hay chỉ sau khi hoàn thành toàn bộ quiz?
2. Ngưỡng nào thì trigger cảnh báo gian lận? (ví dụ: 3 lần chuyển tab, 2 lần copy-paste)
3. Practice mode có cho phép làm lại nhiều lần hay giới hạn 1 lần/quiz?
4. Khi phát hiện gian lận, hệ thống tự động nộp bài hay chỉ flag để review?
5. Practice mode có giới hạn thời gian như exam mode không?

Bắt đầu với Task 0: get_information để hiểu cấu trúc codebase hiện tại và báo cáo vấn đề.
```

**Trạng thái:** Đã hoàn thành
**Kết quả:** Tạo được 4 rules cơ bản cho development workflow

---

## Prompt #2: Cập nhật Rules

**Ngày tạo:** 2025-01-16
**Mục đích:** Cải thiện và bổ sung rules hiện có

```
bạn thấy rule có đang thiếu hay dư thừa gì ko ?
```

**Trạng thái:** Đã hoàn thành
**Kết quả:** Thêm error handling, performance, security vào rules

---

## Prompt #3: Tạo Project Structure Rule

**Ngày tạo:** 2025-01-16
**Mục đích:** Tạo rule về cấu trúc folder và tổ chức code

```
thiếu 1 rules docs nữa , tức là cấu trúc folder code
```

**Trạng thái:** Đã hoàn thành
**Kết quả:** Tạo Rule 04_project_structure_rule.md

---

## Prompt #4: Tạo User Prompts Collection

**Ngày tạo:** 2025-01-16
**Mục đích:** Tạo file lưu trữ các prompt đã sử dụng

```
tạo ra 1 file md nữa gọi là prompt đầu vào của người dùng , tức cursor sẽ lượt qua file read file ( tìm số cuối cùng mà đọc yêu cầu mục đích là để người dùng tự lưu lại các prompt đã dùng của bản thân
```

**Trạng thái:** Đang thực hiện
**Kết quả:** Tạo file user_prompts.md này

---

## Template cho Prompt mới

**Cách thêm prompt mới:**
1. Copy template dưới đây
2. Điền thông tin và nội dung prompt
3. Đánh số thứ tự tiếp theo

```
## Prompt #[SỐ TIẾP THEO]: [TÊN TÍNH NĂNG]

**Ngày tạo:** YYYY-MM-DD
**Mục đích:** [Mô tả ngắn gọn mục đích]

```
[NỘI DUNG PROMPT]
```

**Trạng thái:** [Chưa bắt đầu/Đang thực hiện/Đã hoàn thành]
**Kết quả:** [Mô tả kết quả đạt được]
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
