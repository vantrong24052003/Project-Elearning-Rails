import { ApiService } from './api_service';

export class VideoApi {
  static async analyzeVideoContent(videoId) {
    try {
      return await ApiService.post(`/manage/videos/${videoId}/analyze`);
    } catch (error) {
      console.error('API Error - analyzeVideoContent:', error.message);
      throw error;
    }
  }
}
