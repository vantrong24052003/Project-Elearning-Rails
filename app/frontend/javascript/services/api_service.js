export class ApiService {
  static getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || '';
  }

  static getHeaders(additionalHeaders = {}) {
    return {
      'Content-Type': 'application/json',
      'X-CSRF-Token': this.getCsrfToken(),
      ...additionalHeaders
    };
  }

  static async get(url, options = {}) {
    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: this.getHeaders(options.headers),
        ...options
      });

      if (!response.ok) {
        throw new Error(`GET request failed: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API GET error:', error);
      throw error;
    }
  }

  static async post(url, data, options = {}) {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getHeaders(options.headers),
        body: JSON.stringify(data),
        ...options
      });

      if (!response.ok) {
        throw new Error(`POST request failed: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API POST error:', error);
      throw error;
    }
  }

  static async put(url, data, options = {}) {
    try {
      const response = await fetch(url, {
        method: 'PUT',
        headers: this.getHeaders(options.headers),
        body: JSON.stringify(data),
        ...options
      });

      if (!response.ok) {
        throw new Error(`PUT request failed: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API PUT error:', error);
      throw error;
    }
  }

  static async delete(url, options = {}) {
    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: this.getHeaders(options.headers),
        ...options
      });

      if (!response.ok) {
        throw new Error(`DELETE request failed: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API DELETE error:', error);
      throw error;
    }
  }

  static async request(url, method = 'GET', data = null, options = {}) {
    try {
      const config = {
        method,
        headers: this.getHeaders(options.headers),
        ...options
      };

      if (data && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
        config.body = JSON.stringify(data);
      }

      const response = await fetch(url, config);

      if (!response.ok) {
        throw new Error(`Request failed: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API request error:', error);
      throw error;
    }
  }
}
