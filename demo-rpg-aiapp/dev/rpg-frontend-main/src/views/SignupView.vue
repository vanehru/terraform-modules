<template>
  <div class="signup-wrapper">
    <div class="signup-card">
      <div class="signup-title">とうろく</div>

      <v-text-field dark v-model="userid" label="なまえ" outlined />
      <v-text-field dark v-model="password" label="パスワード" type="password" outlined @keyup.enter="signup" />

      <v-btn color="white" class="mt-4" block @click="signup" :loading="loading" :disabled="loading">セーブデータをつくる</v-btn>
      <v-btn color="white" style="border:solid white 2px" text class="mt-4" block @click="goToLogin">つづきから</v-btn>

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

      <v-dialog v-model="successDialog" max-width="400">
        <v-card>
          <v-card-title class="headline">成功</v-card-title>
          <v-card-text>{{ message }}</v-card-text>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn color="primary" text @click="goToLogin">OK</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </div> 
  </div>
</template>

<script>
import apiService from "@/services/api";

export default {
  name: "SignupView",
  data() {
    return {
      userid: "",
      password: "",
      message: "",
      errorMessage: "",
      dialog: false,
      successDialog: false,
      loading: false
    };
  },
  methods: {
    async signup() {
      if (!this.userid || !this.password) {
        this.errorMessage = "全ての項目を入力してください。";
        this.dialog = true;
        return;
      }

      if (this.password.length < 8) {
        this.errorMessage = "パスワードは8文字以上である必要があります。";
        this.dialog = true;
        return;
      }

      this.loading = true;
      try {
        // Register user
        await apiService.registerUser(this.userid, this.password);
        
        // Initialize player data
        await apiService.initializePlayer(this.userid);
        
        this.message = "ユーザー登録が完了しました。";
        this.successDialog = true;
        this.errorMessage = "";
      } catch (err) {
        if (err.response?.status === 409) {
          this.errorMessage = "このユーザーIDは既に登録されています。";
        } else {
          this.errorMessage = "登録エラー：登録に失敗しました。";
        }
        this.dialog = true;
      } finally {
        this.loading = false;
      }
    },
    goToLogin() {
      this.$router.push("/");
    }
  }
};
</script>

<style>
.signup-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 64px);
}

.signup-card {
  background-color: black;
  border: white solid;
  color: #333;
  padding: 32px;
  border-radius: 8px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 420px;
}

.signup-title {
  font-size: 1.6rem;
  font-weight: bold;
  text-align: center;
  margin-bottom: 24px;
  color: white;
}
</style>
