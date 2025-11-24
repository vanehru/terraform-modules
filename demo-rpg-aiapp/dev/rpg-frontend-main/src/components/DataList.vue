<template>
  <v-container>
    <div class="status-wrapper">
      <table class="table">
        <tr>
          <td>なまえ:</td>
          <td>{{ player.userId }}</td>
        </tr>
        <tr>
          <td>けいけんち:</td>
          <td>{{ player.exp }}</td>
        </tr>
        <tr>
          <td>ちから:</td>
          <td>{{ player.parameter1 }}</td>
        </tr>
        <tr>
          <td>まもり:</td>
          <td>{{ player.parameter2 }}</td>
        </tr>
        <tr>
          <td>すばやさ:</td>
          <td>{{ player.parameter3 }}</td>
        </tr>
      </table>
    </div>
  </v-container>
</template>

<script>
  import DataList from '@/components/DataList.vue' //KakeiboList.vueをインポート
  import axios from "axios";
  import {
    init
  } from "ityped";

  export default {
        name: 'DataView',


    components: {
      DataList,
    },


    name: "AIView",
    data() {
      return {
        message: "",
        messages: [],
        typing: false,
        statMessage: "",
      };
    },
    computed: {
      player() {
        return this.$store.state.player;
      },
      currentLine() {
        return this.$store.getters["player/currentLine"];
      },
      lastLine() {
        return this.$store.getters["player/lastLine"];
      },
      currentImage() {
        return this.imageList[this.imageURL];
      }
    },
    methods: {
      startTyping() {
        const textBox = document.querySelector("#ityped");
        if (!textBox || this.typing) return;
        const text = this.currentLine ? this.currentLine.text : "";
        textBox.innerHTML = "";
        this.typing = true;
        init(textBox, {
          strings: [text],
          typeSpeed: 25,
          backSpeed: 50,
          startDelay: 100,
          backDelay: 500,
          loop: false,
          showCursor: false,
          placeholder: false,
          disableBackTyping: true,
          cursorChar: "|",
          onFinished: () => {
            this.typing = false;
          }
        });
      },
async nextLine() {
  if (this.pendingStatMessage && this.pendingStatMessage.length > 0) {
    this.statMessage = this.pendingStatMessage.join("\n");
    this.pendingStatMessage = null; 
  }

  if (this.lastLine) {
    this.$store.commit("player/nextLine");
    this.$nextTick(this.startTyping);
  } else {
    const ev = this.player.currentEventId + 1;
    this.$store.commit("player/setProgress", { eventId: ev, seq: 0 });
    await this.$store.dispatch("player/loadEvent");
    this.$nextTick(this.startTyping);
    this.statMessage = "";
  }
},
async sendMessage() {
  const trimmed = (this.message || "").trim();
  if (!trimmed) return;

  const textBox = document.querySelector("#ityped");
  if (textBox) {
    textBox.innerHTML = "";
    this.typing = true;
    init(textBox, {
      strings: [trimmed],
      typeSpeed: 25,
      backSpeed: 50,
      loop: false,
      showCursor: false,
      onFinished: () => {
        this.typing = false;
      }
    });
  }

  try {
    const resp = await axios.post(
      "https://rpg-funcapp-guddfdfpg8h8ere4.japaneast-01.azurewebsites.net/api/OpenAI?",
      { message: trimmed }
    );
    const contentText = resp.data.Content[0].Text;
    const parsed = JSON.parse(contentText);

    const before = {
      p1: this.player.parameter1,
      p2: this.player.parameter2,
      p3: this.player.parameter3,
      exp: this.player.exp
    };

    this.$store.commit("player/addParams", {
      p1: Number(parsed.Intelligence) || 0,
      p2: Number(parsed.Vitality) || 0,
      p3: Number(parsed.Empathy) || 0
    });

    this.pendingStatMessage = [];
    const diff1 = this.player.parameter1 - before.p1;
    const diff2 = this.player.parameter2 - before.p2;
    const diff3 = this.player.parameter3 - before.p3;
    const diffExp = this.player.exp - before.exp;

    if (diff1) this.pendingStatMessage.push(`ちからが ${diff1} 上がった！`);
    if (diff2) this.pendingStatMessage.push(`まもりが ${diff2} 上がった！`);
    if (diff3) this.pendingStatMessage.push(`すばやさが ${diff3} 上がった！`);
    if (diffExp) this.pendingStatMessage.push(`けいけんちが ${diffExp} 増えた！`);

  } catch (e) {
    console.error(e);
    this.pendingStatMessage = ["評価に失敗しました。"];
  }

  this.message = "";
}

    },
    mounted: async function() {
      await this.$store.dispatch("player/loadPlayer");
      await this.$store.dispatch("player/loadEvent");
      this.startTyping();
      const self = this;
      setInterval(function() {
        self.imageURL = (self.imageURL + 1) % self.imageList.length;
      }, 80);
    }
  };
</script>