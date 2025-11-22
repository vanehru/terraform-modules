<template>
  <div class="signup-wrapper">
    <div class="signup-card">
      <div class="signup-title">とうろく</div>

      <v-text-field dark v-model="userid" label="なまえ" outlined />
      <v-text-field dark v-model="password" label="パスワード" type="password" outlined />

      <v-btn color="white" class="mt-4" block @click="signup">セーブデータをつくる</v-btn>
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
import axios from "axios";

export default {
  name: "SignupView",
  data() {
    return {
      userid: "",
      password: "",
      displayName: "",
      message: "",
      errorMessage: "",
      dialog: false,
      successDialog: false
    };
  },
  methods: {
async signup() {
  if (!this.userid || !this.password) {
    this.errorMessage = "全ての項目を入力してください。";
    this.dialog = true;
    return;
  }

  try {
    const response = await axios.post(
      "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/INSERTUSER",
      {
        ID: this.userid,
        Password: this.password,
        Name: this.userid
      }
    );

    console.log(response);

    if (response.data === "登録結果:1件のユーザー情報を登録しました。") {
      const response2 = await axios.post(
        "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/INSERTPLAYER",
        {
          UserId: this.userid
        }
      );
      this.message = response2.data.result;
    } else {
      this.message = response.data;
    }

    this.successDialog = true;
    this.errorMessage = "";
  } catch (err) {
    this.errorMessage = "登録エラー：" + (err.response?.data || err.message);
    this.dialog = true;
  }
},
goToLogin() {
  this.$router.push("/"); // IndexView に戻る
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
