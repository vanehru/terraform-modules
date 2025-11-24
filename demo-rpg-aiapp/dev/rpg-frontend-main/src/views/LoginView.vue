<template>
  <div class="login-wrapper">
    <div class="login-card">
      <div class="login-title"></div>

      <v-text-field dark v-model="userid" label="ユーザーID" outlined />
      <v-text-field dark v-model="password" label="パスワード" type="password" outlined @keyup.enter="login" />

      <v-btn color="white" light block class="mt-4" @click="login" :loading="loading" :disabled="loading">つづきから</v-btn>

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
import apiService from "@/services/api";

export default {
  name: "LoginView",
  data() {
    return {
      userid: "",
      password: "",
      errorMessage: "",
      dialog: false,
      loading: false
    };
  },
  methods: {
    async login() {
      if (!this.userid || !this.password) {
        this.errorMessage = "ユーザーIDとパスワードを入力してください。";
        this.dialog = true;
        return;
      }

      this.loading = true;
      try {
        const response = await apiService.login(this.userid, this.password);

        if (response.data.result === "success") {
          this.$store.commit("player/setUserId", this.userid);
          await this.$store.dispatch("player/loadPlayer");
          this.$router.push("/aiview");
        } else {
          this.errorMessage = "ログインに失敗しました。";
          this.dialog = true;
        }
      } catch (err) {
        this.errorMessage = "ログインエラー：ユーザーIDまたはパスワードが正しくありません。";
        this.dialog = true;
      } finally {
        this.loading = false;
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
