<template>
  <v-container>
    <v-row class="text-h4 mb-4" justify="center">プレイヤー一覧</v-row>

<v-data-table
  :headers="headers"
  :items="players"
>
</v-data-table>
  </v-container>
</template>

<script>
import axios from "axios";

export default {
  name: "DataView",
  data() {
    return {
      players: [],
      headers: [
        { text: "User ID", value: "UserId" },
        { text: "経験値", value: "Exp" },
        { text: "ちから", value: "Parameter1" },
        { text: "まもり", value: "Parameter2" },
        { text: "すばやさ", value: "Parameter3" },
        { text: "すばやさ", value: "Parameter4" },
        { text: "章", value: "CurrentEventId" },
      ],
    };
  },
  async mounted() {
    try {
      console.log("start");
    const response = await axios.post(
      "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/SELECTALLPLAYER");
      this.players = response.data.PlayerDataList || [];
            console.log("start");

    } catch (err) {
      console.error("プレイヤーデータ取得失敗:", err);
    }
  },
};
</script>
