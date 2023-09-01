<template>
  <div class="app-container">
    <div style="display: flex;justify-content: flex-start;align-items: flex-start">
      <div style="border: 1px solid gray; width: 360px;margin-right: 8px">
        <fight-render :coords="owner.coords"/>
      </div>
      <div>
        <div style="width: 180px;height: 144px">
          <div>
            <Block :block="nextShape"/>
          </div>
        </div>
        <div>
          <h2>{{ `当前分数: ${owner.currentScore}` }}</h2>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import FightRender from "./FightRender";
  import Block from "./Block";

  export default {
    name: 'Fight',
    components: {
      Block,
      FightRender
    },
    data() {
      return {
        prevOff: [0, 3],
        fallSpeed: 1,
        keyTime: null,
        renderTime: null,
        checkTime: null,
        sense: {
          id: null,
          resource: {}
        },
        nextShape: [null, null],
        owner: {
          id: 1,
          offX: 0,
          offY: 3,
          currentScore: 0,
          coords: [],
          gameOver: 0,
          moveCube: {
            id: 1,
            type: 1,
          }
        },
        player: {
          id: null,
          currentScore: 0,
          coords: [],
          moveCube: {
            id: null,
            type: null
          }
        },

        renderIns: null,
        renderIns2: null,
      }
    },
    mounted() {
      this.init0();
      this.init1();
    },
    methods: {
      init0() {
        this.keyTime = new Date();
        this.owner.coords = this.$store.state.coordsTemplate;
        this.randomNext();
        this.owner.moveCube.id = this.nextShape[0];
        this.owner.moveCube.type = this.nextShape[1];
        this.randomNext();
        this.updateCoords();
      },

      init1() {
        this.renderTime = new Date();
        window.addEventListener('keydown', this.calcCore)
        window.addEventListener('keyup', this.moderate)
        setTimeout(()=>{
          this.renderIns = setInterval(this.render, 101);
          this.renderIns2 = setInterval(this.render2, 100);
        }, 3000)
      },

      randomNext() {
        let val = Math.ceil(Math.random() * 100);
        this.nextShape[0] = val % this.$store.state.shapeList.length === 0 ? this.$store.state.shapeList.length : val % this.$store.state.shapeList.length;
        this.$set(this.nextShape, 0, this.nextShape[0]);
        for (let el of this.$store.state.shapeList) {
          if (el.id === this.nextShape[0]) {
            let len = 0;

            for (let k in el.shape) {
              len++;
            }

            this.nextShape[1] = Math.min(Math.max(Math.ceil(Math.random() * 10), 1), len);
            this.$set(this.nextShape, 1, this.nextShape[1]);
            break;
          }
        }
      },

      calcCore(e) {
        let now = new Date();
        if (now.getTime() - this.keyTime.getTime() < 100) {
          return;
        }

        if (e.key === 'w') {
          if (this.isTransfer()) {
            this.calcTransfer();
          } else if (this.isMirrorTransfer()) {
            this.calcMirrorTransfer();
          }
        } else if (e.key === 'd') {
          if (this.isRight()) {
            this.calcRight();
          }
        } else if (e.key === 'a') {
          if (this.isLeft()) {
            this.calcLeft();
          }
        } else if (e.key === 's') {
          this.fallSpeed = 2
        }
        this.keyTime = now;
      },

      moderate(e) {
        if (e.key === 's') {
          this.fallSpeed = 1;
        }
      },

      render() {
        let interval = 1000;
        if (this.fallSpeed > 1) {
          interval = 100;
        }
        let now = new Date();
        if (now.getTime() - this.renderTime.getTime() >= interval) {
          this.renderTime = now;
          this.clearMoveCoords();
          this.owner.offX = Math.min(this.owner.offX + 1, 15);
          this.updateCoords();
        }
      },
      render2() {
        if (this.bottomingDetection()) {
          return;
        }
        this.updateCoords();

        let shape = this.getShape();
        for (let i = 0; i < 3; i++) {
          let row = this.owner.coords[i];
          let idx = 0;
          for (let col of row) {
            if (col > 0) {
              let flag = true;
              for (let el of shape) {
                if (el[0] + this.owner.offX === i && el[1] + this.owner.offY === idx) {
                  flag = false;
                  break
                }
              }

              if (flag) {
                this.gameOver();
              }
            }

            idx++;
          }
        }
      },

      getShape() {
        let shapeList = this.$store.state.shapeList;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            return el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
          }
        }
        return null;
      },

      isLeft() {
        let shape = this.getShape();

        if (!shape) {
          return;
        }

        let coords = JSON.parse(JSON.stringify(this.owner.coords));
        for (let xy of shape) {
          coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }
        return !this.collisionDetection(shape, coords, this.owner.offX, this.owner.offY - 1);
      },
      calcLeft() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            break;
          }
        }

        if (!shape) {
          return;
        }

        for (let xy of shape) {
          this.owner.coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }

        this.owner.offY -= 1;
        this.updateCoords();
      },

      isRight() {
        let shape = this.getShape();

        if (!shape) {
          return;
        }

        let coords = JSON.parse(JSON.stringify(this.owner.coords));
        for (let xy of shape) {
          coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }
        return !this.collisionDetection(shape, coords, this.owner.offX, this.owner.offY + 1);
      },
      calcRight() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            break;
          }
        }

        if (!shape) {
          return;
        }

        for (let xy of shape) {
          this.owner.coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }

        this.owner.offY += 1;
        this.updateCoords();
      },

      isTransfer() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        let shapeRoot = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            shapeRoot = el.shape;
            break;
          }
        }
        if (!shape) {
          return false;
        }
        let coords = JSON.parse(JSON.stringify(this.owner.coords));
        for (let xy of shape) {
          coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }

        let nextType = this.owner.moveCube.type + 1;
        let len = 0;
        for (let k in shapeRoot) {
          len++;
        }
        shape = shapeRoot[nextType % len === 0 ? len : nextType % len];
        return !this.collisionDetection(shape, coords, this.owner.offX, this.owner.offY);
      },
      calcTransfer() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            break;
          }
        }

        if (!shape) {
          return;
        }

        for (let xy of shape) {
          this.owner.coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }

        this.owner.moveCube.type = this.owner.moveCube.type + 1;
        this.updateCoords();
      },

      isMirrorTransfer() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        let shapeRoot = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            shapeRoot = el.shape;
            break;
          }
        }

        if (!shape) {
          return false;
        }

        let coords = JSON.parse(JSON.stringify(this.owner.coords));
        for (let xy of shape) {
          coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }

        let nextType = this.owner.moveCube.type + 1;
        let len = 0;
        for (let k in shapeRoot) {
          len++;
        }
        shape = shapeRoot[nextType % len === 0 ? len : nextType % len];

        let maxY = 0;
        for (let xy of shape) {
          maxY = Math.max(maxY, xy[1]);
        }

        for (let offY = 1; offY <= maxY; ++offY) {
          if (!this.collisionDetection(shape, coords, this.owner.offX, this.owner.offY - offY)) {
            return true;
          }
        }

        return false;
      },
      calcMirrorTransfer() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        let shapeRoot = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            shapeRoot = el.shape;
            break;
          }
        }

        if (!shape) {
          return;
        }

        let shapeBack = JSON.parse(JSON.stringify(shape));
        let coords = JSON.parse(JSON.stringify(this.owner.coords));
        for (let xy of shape) {
          coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
        }

        let nextType = this.owner.moveCube.type + 1;
        let len = 0;
        for (let k in shapeRoot) {
          len++;
        }
        shape = shapeRoot[nextType % len === 0 ? len : nextType % len];

        let maxY = 0;
        for (let xy of shape) {
          maxY = Math.max(maxY, xy[1]);
        }

        for (let offY = 1; offY <= maxY; ++offY) {
          if (!this.collisionDetection(shape, coords, this.owner.offX, this.owner.offY - offY)) {
            for (let xy of shapeBack) {
              this.owner.coords[xy[0]+this.owner.offX][xy[1]+this.owner.offY] = 0;
            }
            this.owner.moveCube.type = this.owner.moveCube.type + 1;
            this.owner.offY -= offY;
            this.updateCoords();
            break;
          }
        }
      },

      clearMoveCoords() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        let shapeRoot = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            shapeRoot = el.shape;
            break;
          }
        }
        if (!shape) {
          return;
        }

        for (let xy of shape) {
          this.$set(this.owner.coords[xy[0]+this.owner.offX], xy[1]+this.owner.offY, 0);
        }
      },
      clearPrevCoords() {
        let shapeList = this.$store.state.shapeList;
        let shape = null;
        let shapeRoot = null;
        for (let el of shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            shapeRoot = el.shape;
            break;
          }
        }
        if (!shape) {
          return;
        }

        for (let xy of shape) {
          this.$set(this.owner.coords[xy[0]+this.prevOff[0]], xy[1]+this.prevOff[1], 0);
        }
      },

      updateCoords() {
        let shape = null;
        for (let el of this.$store.state.shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            break;
          }
        }
        for (let xy of shape) {
          this.$set(this.owner.coords[xy[0]+this.owner.offX], xy[1]+this.owner.offY, xy[2]);
        }
      },

      collisionDetection(shape, coords, x, y) {
        if (x > 15 || x < 0) {
          return true;
        }

        if (y > 9 || y < 0) {
          return true;
        }

        for (let xy of shape) {
          if (xy[0] + x > 15 || xy[0] + x < 0) {
            return true;
          }
          if (xy[1] + y > 9 || xy[1] + y < 0) {
            return true;
          }
        }

        for (let xy of shape) {
          if (coords[xy[0] + x][xy[1] + y] > 0) {
            return true;
          }
        }
        return false;
      },

      bottomingDetection() {
        let shape = null;
        for (let el of this.$store.state.shapeList) {
          if (el.id === this.owner.moveCube.id) {
            let len = 0;
            for (let k in el.shape) {
              len++;
            }
            shape = el.shape[this.owner.moveCube.type % len === 0 ? len : this.owner.moveCube.type % len];
            break;
          }
        }

        if (!shape) {
          return false;
        }

        let arr = {};
        for (let i = 0; i < 10; ++i) {
          for (let xy of shape) {
            if (xy[1] === i) {
              if (arr.hasOwnProperty(i)) {
                arr[i] = xy[0] > arr[i][0] ? xy : arr[i];
              } else {
                arr[i] = xy;
              }
            }
          }
        }

        let flag = false;
        for (let k in arr) {
          let posX = arr[k][0] + this.owner.offX + 1;
          if (posX > 15) {
            flag = true;
            break
          }
        }
        if (!flag) {
          for (let k in arr) {
            let posX = arr[k][0] + this.owner.offX + 1;
            let posY = arr[k][1] + this.owner.offY;
            if (this.owner.coords[posX][posY] > 0) {
              flag = true;
              break;
            }
          }
        }

        if (flag) {
          this.calcScore();

          this.refreshMove();
        }
        return flag;
      },

      refreshMove() {
        let x = this.owner.offX;
        let y = this.owner.offY;
        let id = this.owner.moveCube.id;
        let type = this.owner.moveCube.type;
        this.owner.offX = 0;
        this.owner.offY = 3;
        this.owner.moveCube.id = this.nextShape[0];
        this.owner.moveCube.type = this.nextShape[1];
        this.randomNext();

        let shape = this.getShape();
        if (this.collisionDetection(shape, this.owner.coords, this.owner.offX, this.owner.offY)) {
          this.owner.offX = x;
          this.owner.offY = y;
          this.owner.moveCube.id = id;
          this.owner.moveCube.type = type;
          this.gameOver();
        } else {
          clearInterval(this.renderIns);
          setTimeout(()=>{
            this.renderIns = setInterval(this.render, 101);
          }, 100)
        }
      },

      gameOver() {
        if (this.gameOver > 0) {
          return;
        }
        this.gameOver = 1;
        clearInterval(this.renderIns);
        clearInterval(this.renderIns2);
        window.removeEventListener('keyup', this.moderate);
        window.removeEventListener('keydown', this.calcCore);
        setTimeout(()=>{
          alert("game over");
        }, 1000)
      },

      calcScore() {
        let newCoords = [];
        let scoreLine = [];
        let idx = 0;
        for (let row of this.owner.coords) {
          let flag = false;
          for (let col of row) {
            if (col === 0) {
              flag = true;
              break;
            }
          }

          if (flag) {
            newCoords.push(row);
          } else {
            scoreLine.push(idx);
          }

          idx++;
        }

        let len = newCoords.length;
        for (let i = 0; i < 16 - len; i++) {
          newCoords.unshift([0,0,0,0,0,0,0,0,0,0]);
        }
        this.owner.coords = newCoords;

        if (scoreLine.length === 1) {
          this.owner.currentScore += 10;
        } else if (scoreLine.length === 2) {
          this.owner.currentScore += 20;
        } else if (scoreLine.length === 3) {
          if (scoreLine[0] + 1 === scoreLine[2] && scoreLine[0] + 1 === scoreLine[3]) {
            this.owner.currentScore += 40;
          } else {
            this.owner.currentScore += 30;
          }
        } else if (scoreLine.length === 4) {
          this.owner.currentScore += 80;
        }
      },
    }
  }
</script>
