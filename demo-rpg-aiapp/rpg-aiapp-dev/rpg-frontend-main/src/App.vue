<template>
  <v-app class="app-background">
    <v-app-bar app color="black" dark>
      <div class="d-flex align-center">
        <v-img alt="Logo" class="shrink mr-2" contain src="https://i.gyazo.com/12213166757a7551808fbd6fd409c97c.png" transition="scale-transition" width="108" />
      </div>
      なまえ: {{ userId }} Lv: {{ level }}

      <v-spacer></v-spacer>

      <v-btn color="black" @click="saveData">セーブ</v-btn>
      <v-btn text to="/dataview" tag="router-link">データ</v-btn>
      <v-btn @click="playBGM">bgm</v-btn>
            <v-btn text to="/" tag="router-link">ログアウト</v-btn>

      <audio ref="bgm" :src="bgmUrl" loop></audio>
    </v-app-bar>

    <v-main>
      <router-view />
    </v-main>
  </v-app>
</template>

<script>
  export default {
    name: 'App',
    data() {
      return {
        bgmUrl: "https://www.music-note.jp/bgm/mp3/village.mp3"
      };
    },
    computed: {
      userId() {
        return this.$store.state.player.userId;
      },
      level() {
        return Math.floor((this.$store.state.player.exp || 0) / 100);
      }
    },
    methods: {
      async saveData() {
        try {
          await this.$store.dispatch("player/saveAll");
          alert("セーブ完了");
        } catch (e) {
          console.error(e);
          alert("セーブ失敗");
        }
      },
      async playBGM() {
        const bgm = this.$refs.bgm;
        if (bgm) {
          await bgm.play();
          if (bgm.volume == 0 || bgm.volume == 1){
            bgm.volume = 0.1;
          }else{
            bgm.volume = 0;
          }
        }
      }
      
    }
  };
</script>

<style>
  #app {
    height: 100%;
    background-color: white;
  }
  </style>