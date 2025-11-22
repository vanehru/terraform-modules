import axios from "axios";

export default {
  namespaced: true,

  state: {
    userId: "なまえ",
    charId: 0,
    exp: 0,
    parameter1: 0,
    parameter2: 0,
    parameter3: 0,
    parameter4: 0,
    currentEventId: 1,
    currentLine: 0,
    lines: []
  },

  getters: {
    currentLine(state) {
      return state.lines[state.currentLine] || null;
    },
    Total(state) {
      const Sum = state.Items.reduce((Sum, item) => Sum + item.Amount, 0);
      return Sum;
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
      console.log(state);
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
      if (state.exp >= 1500) {
        let maxParam = Math.max(
          state.parameter1,
          state.parameter2,
          state.parameter3,
          state.parameter4
        );
        if (maxParam === state.parameter1) {
          state.charId = 10;
        } else if (maxParam === state.parameter2) {
          state.charId = 20;
        } else if (maxParam === state.parameter3) {
          state.charId = 30;
        } else if (maxParam === state.parameter4) {
          state.charId = 40;
        } else {
          state.charId = 0;
          console.log("進化エラー");
        }
        state.lines.push({
          speaker: "SYSTEM",
          text: `なんと、${state.userId}は進化した！`
        });
        state.currentEventId = 999;
      }
    },
    setProgress(state, item) {
      if (item.eventId !== undefined && item.eventId !== null) {
        state.currentEventId = item.eventId;
      }
      if (item.seq !== undefined && item.seq !== null) {
        state.currentLine = item.seq;
      }
    }
  },

  actions: {
    async loadPlayer({ state, commit }) {
      try {
        const response = await axios.post(
          "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/SELECTPLAYER",
          { UserId: state.userId }
        );

        const playerData = response.data.PlayerDataList[0];
        commit("setPlayer", {
          userId: playerData.UserId,
          charId: playerData.CharId,
          exp: playerData.Exp,
          parameter1: playerData.Parameter1,
          parameter2: playerData.Parameter2,
          parameter3: playerData.Parameter3,
          parameter4: playerData.Parameter4,
          currentEventId: playerData.CurrentEventId ?? 1,
          currentLine: playerData.CurrentSeq ?? 0
        });
      } catch (e) {
        console.error("プレイヤーデータ取得失敗:", e);
        throw e;
      }
    },

    async loadEvent({ state, commit }) {
      try {
        const url =
          "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/SELECTEVENTS?eventId=" +
          state.currentEventId;
        //select * from eventtable where eventid=?? orderby line; ←SQL文
        const response = await axios.get(url);
        const eventLines = response.data.EventLines || [];
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
      await axios.post(
        "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/UPDATE",
        {
          UserId: state.userId,
          CharId: state.charId,
          Exp: state.exp,
          Parameter1: state.parameter1,
          Parameter2: state.parameter2,
          Parameter3: state.parameter3,
          Parameter4: state.parameter4,
          CurrentEventId: state.currentEventId,
          CurrentSeq: state.currentLine
        }
      );
    }
  }
};
