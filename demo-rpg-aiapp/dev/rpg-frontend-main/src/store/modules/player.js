import apiService from "@/services/api";

// Constants
const EVOLUTION_THRESHOLD = 1500;
const CHAR_ID_POWER = 10;
const CHAR_ID_IMAGINATION = 20;
const CHAR_ID_WISDOM = 30;
const CHAR_ID_SPEED = 40;
const CHAR_ID_DEFAULT = 0;
const EVENT_ID_END = 999;

export default {
  namespaced: true,

  state: {
    userId: null,
    charId: 0,
    exp: 0,
    parameter1: 0,
    parameter2: 0,
    parameter3: 0,
    parameter4: 0,
    currentEventId: 1,
    currentLine: 0,
    lines: [],
    loading: false,
    error: null
  },

  getters: {
    currentLine(state) {
      return state.lines[state.currentLine] || null;
    },
    Total(state) {
      // Legacy getter - kept for compatibility
      return state.Items ? state.Items.reduce((Sum, item) => Sum + item.Amount, 0) : 0;
    },
    lastLine(state) {
      return state.currentLine < state.lines.length - 1;
    },
    status(state) {
      return {
        exp: state.exp,
        p1: state.parameter1,
        p2: state.parameter2,
        p3: state.parameter3,
        p4: state.parameter4
      };
    }
  },

  mutations: {
    setPlayer(state, item) {
      state.userId = item.userId;
      state.charId = item.charId;
      state.exp = item.exp;
      state.parameter1 = item.parameter1;
      state.parameter2 = item.parameter2;
      state.parameter3 = item.parameter3;
      state.parameter4 = item.parameter4;
      state.currentEventId = item.currentEventId;
      state.currentSeq = item.currentSeq;
    },
    setUserId(state, userId) {
      state.userId = userId;
    },
    setLines(state, lines) {
      state.lines = lines;
      state.currentLine = 0;
    },
    nextLine(state) {
      if (state.currentLine < state.lines.length) {
        state.currentLine++;
      }
    },
    addParams(state, item) {
      const p1 = item.p1 || 0,
        p2 = item.p2 || 0,
        p3 = item.p3 || 0,
        p4 = item.p4 || 0;
      state.parameter1 += p1;
      state.parameter2 += p2;
      state.parameter3 += p3;
      state.parameter4 += p4;
      state.exp += p1 + p2 + p3 + p4;
      if (state.exp >= EVOLUTION_THRESHOLD) {
        let maxParam = Math.max(
          state.parameter1,
          state.parameter2,
          state.parameter3,
          state.parameter4
        );
        if (maxParam === state.parameter1) {
          state.charId = CHAR_ID_POWER;
        } else if (maxParam === state.parameter2) {
          state.charId = CHAR_ID_IMAGINATION;
        } else if (maxParam === state.parameter3) {
          state.charId = CHAR_ID_WISDOM;
        } else if (maxParam === state.parameter4) {
          state.charId = CHAR_ID_SPEED;
        } else {
          state.charId = CHAR_ID_DEFAULT;
        }
        state.lines.push({
          speaker: "SYSTEM",
          text: `なんと、${state.userId}は進化した！`
        });
        state.currentEventId = EVENT_ID_END;
      }
    },
    setProgress(state, item) {
      if (item.eventId !== undefined && item.eventId !== null) {
        state.currentEventId = item.eventId;
      }
      if (item.seq !== undefined && item.seq !== null) {
        state.currentLine = item.seq;
      }
    },
    setLoading(state, loading) {
      state.loading = loading;
    },
    setError(state, error) {
      state.error = error;
    }
  },

  actions: {
    async loadPlayer({ state, commit }) {
      commit('setLoading', true);
      commit('setError', null);
      try {
        const response = await apiService.getPlayer(state.userId);

        if (!response.data.List || response.data.List.length === 0) {
          throw new Error('Player data not found');
        }

        const playerData = response.data.List[0];
        commit("setPlayer", {
          userId: playerData.UserId,
          charId: playerData.CharId,
          exp: playerData.Exp,
          parameter1: playerData.Parameter1,
          parameter2: playerData.Parameter2,
          parameter3: playerData.Parameter3,
          parameter4: playerData.Parameter4,
          currentEventId: playerData.CurrentEventId ?? 1,
          currentSeq: playerData.CurrentSeq ?? 0
        });
      } catch (e) {
        commit('setError', 'Failed to load player data');
        throw e;
      } finally {
        commit('setLoading', false);
      }
    },

    async loadEvent({ state, commit }) {
      try {
        const response = await apiService.getEvents(state.currentEventId);
        const eventLines = response.data.List || [];
        const lines = [];
        for (let i = 0; i < eventLines.length; i++) {
          if (eventLines[i].Speaker === "じぶん") {
            eventLines[i].Speaker = state.userId;
          }

          lines.push({
            speaker: eventLines[i].Speaker || "",
            text: eventLines[i].Text
          });
        }
        commit("setLines", lines);
        if (state.currentLine > 0 && state.currentLine < lines.length) {
          commit("setProgress", {
            eventId: state.currentEventId,
            seq: state.currentLine
          });
        }
      } catch (e) {
        commit("setLines", [
          { speaker: "だれか", text: "イベントID: " + state.currentEventId },
          { speaker: "だれか", text: "ひとことめ" },
          { speaker: "だれか", text: "ふたことめ" },
          { speaker: "じぶん", text: "最初のセリフ" },
          { speaker: "じぶん", text: "次のセリフ" }
        ]);
      }
    },

    async saveAll({ state }) {
      await apiService.updatePlayer({
        UserId: state.userId,
        CharId: state.charId,
        Exp: state.exp,
        Parameter1: state.parameter1,
        Parameter2: state.parameter2,
        Parameter3: state.parameter3,
        Parameter4: state.parameter4,
        CurrentEventId: state.currentEventId,
        CurrentSeq: state.currentLine
      });
    }
  }
};
