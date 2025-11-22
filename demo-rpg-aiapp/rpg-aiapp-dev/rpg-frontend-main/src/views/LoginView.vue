<template>
  <div class="login-wrapper">
    <div class="login-card">
      <div class="login-title"></div>

      <v-text-field dark v-model="userid" label="ユーザーID" outlined />
      <v-text-field dark v-model="password" label="パスワード" type="password" outlined />

      <v-btn color="white" light block class="mt-4" @click="login">つづきから</v-btn>

      <v-btn color="white" style="border:solid white 2px" text to="/signupview" block class="mt-4" tag="router-link">はじめから</v-btn>

      <v-dialog v-model="dialog" max-width="400">
        <v-card>
          <v-card-title class="headline">エラー</v-card-title>
          <v-card-text>{{ errorMessage }}</v-card-text>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn color="primary" text @click="dialog = false">閉じる</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "IndexView",
  data() {
    return {
      userid: "",
      password: "",
      errorMessage: "",
      dialog: false
    };
  },
  methods: {
async login() {
  try {
    const response = await axios.post(
      "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/LOGIN",
      {
        ID: this.userid,
        Password: this.password
      }
    );
      console.log(response.data.result);

    if (response.data.result === "Succeeded") {
      console.log("aaa");
      this.$store.commit("player/setUserId", this.userid);

      await this.$store.dispatch("player/loadPlayer");

      this.$router.push("/aiview");
    } else {
      this.errorMessage = response.data.Message || "ログインに失敗しました。";
      this.dialog = true;
    }
  } catch (err) {
    console.error("ログインエラー:", err);
    this.errorMessage = "ログインエラー：" + (err.response?.data || err.message);
    this.dialog = true;
  }
}
  }
};
</script>

<style scoped>
.login-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 64px);
}

.login-card {
  background-color: black;
  border: white solid;
  color: #333;
  padding: 32px;
  border-radius: 8px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 420px;
}

.login-title {
  font-size: 1.6rem;
  font-weight: bold;
  text-align: center;
  margin-bottom: 24px;
  color: white;
}
</style>
