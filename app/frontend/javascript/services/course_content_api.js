import { ApiService } from './api_service';

export class CourseContentApi {
  static async getCourseChapters(courseId) {
    return await ApiService.get(`/manage/quizzes/new.json?get_content_type=course_chapters&course_id=${courseId}`);
  }

  static async getChapterLessons(chapterId) {
    return await ApiService.get(`/manage/quizzes/new.json?get_content_type=chapter_lessons&chapter_id=${chapterId}`);
  }

  static async getLessonVideos(lessonId) {
    return await ApiService.get(`/manage/quizzes/new.json?get_content_type=lesson_videos&lesson_id=${lessonId}`);
  }

  static async getVideoDetails(videoId) {
    return await ApiService.get(`/manage/quizzes/new.json?get_content_type=video_details&video_id=${videoId}`);
  }
}
