import axios from "axios";

export default {
  namespaced: true,
  state: {
    Items: [
      {
        Date: "日付",
        Inout: "収支",
        Category: "カテゴリ",
        Amount: "0"
      }
    ]
  },
  getters: {
    Total(state) {
      const Sum = state.Items.reduce((Sum, item) => Sum + item.Amount, 0);
      return Sum;
    },   
  },
  mutations: {
    setApi(state, data) {
      state.Items = data.map((item) => ({
        Date: item.Date,
        Inout: item.Inout,
        Category: item.Category,
        Amount: item.Amount
      }));
    }
  },
  actions: {
    async API({ commit }) {
      try {
        const response = await axios.get(
          "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/SELECT?"
        );
        const KakeiboList = response.data.List;
        const Items = KakeiboList.map((kakeibo) => ({
          Date: kakeibo.Date.slice(0,10),
          Inout: kakeibo.Inout,
          Category: kakeibo.Category,
          Amount: kakeibo.Amount
        }));
        commit("setApi", Items);
      } catch (error) {
        console.error("API取得できませんでした:", error);
      }
    }
  }
};