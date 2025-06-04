#!/usr/bin/env ruby

# Test pagination với dữ liệu rỗng
puts "Testing pagination component..."

# Giả lập collection rỗng
class EmptyCollection
  def respond_to?(method)
    %i[total_count offset_value limit_value current_page total_pages].include?(method)
  end

  def total_count
    0
  end

  def offset_value
    0
  end

  def limit_value
    10
  end

  def current_page
    1
  end

  def total_pages
    1
  end
end

collection = EmptyCollection.new
pagination_label = "test item"

puts "Collection info:"
puts "- total_count: #{collection.total_count}"
puts "- current_page: #{collection.current_page}"
puts "- total_pages: #{collection.total_pages}"
puts ""

# Test logic từ pagination component
if collection.respond_to?(:total_count) && collection.total_count > 0
  puts "Display: Hiển thị #{collection.offset_value + 1}-#{[collection.offset_value + collection.limit_value, collection.total_count].min} trong số #{collection.total_count} #{pagination_label}"
else
  puts "Display: Không có #{pagination_label} nào được tìm thấy"
end

# Test pagination controls
if collection.respond_to?(:total_pages) && collection.respond_to?(:current_page) && collection.total_pages > 1
  puts "Pagination controls: VISIBLE"
else
  puts "Pagination controls: HIDDEN (0 or 1 page only)"
end

puts ""
puts "✅ Pagination should always show info, but hide controls when 0 or 1 page"
