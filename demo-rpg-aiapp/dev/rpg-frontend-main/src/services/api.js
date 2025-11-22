/**
 * API Service - Centralized API configuration and helpers
 */
import axios from 'axios';

// Base API URL from environment variable
const API_BASE_URL = process.env.VUE_APP_API_BASE_URL || 'https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api';

/**
 * Create axios instance with default config
 */
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 second timeout
});

/**
 * API endpoints
 */
export const API_ENDPOINTS = {
  LOGIN: '/LOGIN',
  INSERT_USER: '/INSERTUSER',
  INSERT_PLAYER: '/INSERTPLAYER',
  SELECT_PLAYER: '/SELECTPLAYER',
  SELECT_ALL_PLAYER: '/SELECTALLPLAYER',
  SELECT_EVENTS: '/SELECTEVENTS',
  UPDATE: '/UPDATE',
  OPENAI: '/OpenAI',
};

/**
 * API service methods
 */
export default {
  /**
   * User login
   */
  login(userId, password) {
    return apiClient.post(API_ENDPOINTS.LOGIN, {
      UserId: userId,
      Password: password,
    });
  },

  /**
   * Register new user
   */
  registerUser(userId, password) {
    return apiClient.post(API_ENDPOINTS.INSERT_USER, {
      UserId: userId,
      Password: password,
    });
  },

  /**
   * Initialize player data
   */
  initializePlayer(userId, charId = 1) {
    return apiClient.post(API_ENDPOINTS.INSERT_PLAYER, {
      UserId: userId,
      CharId: charId,
    });
  },

  /**
   * Get player data by UserId
   */
  getPlayer(userId) {
    return apiClient.post(API_ENDPOINTS.SELECT_PLAYER, {
      UserId: userId,
    });
  },

  /**
   * Get all players
   */
  getAllPlayers() {
    return apiClient.get(API_ENDPOINTS.SELECT_ALL_PLAYER);
  },

  /**
   * Get events by eventId
   */
  getEvents(eventId) {
    return apiClient.get(`${API_ENDPOINTS.SELECT_EVENTS}?eventId=${eventId}`);
  },

  /**
   * Update player data
   */
  updatePlayer(playerData) {
    return apiClient.post(API_ENDPOINTS.UPDATE, playerData);
  },

  /**
   * Call OpenAI API
   */
  callOpenAI(message) {
    return apiClient.post(API_ENDPOINTS.OPENAI, {
      message: message,
    });
  },
};
