#!/bin/bash
# DummyC テスト一括実行
# 使い方: bash runtests.sh

PASS=0
FAIL=0

run() {
  local name="$1"
  local file="$2"
  local want="$3"
  local ll="${file%.dc}.ll"
  rm -f "$ll"
  ./dcc "$file" > /dev/null 2>&1
  if [ ! -f "$ll" ]; then
    printf '  FAIL  %-24s (compile error)\n' "$name"
    FAIL=$((FAIL+1))
    return
  fi
  lli "$ll" > /dev/null 2>&1
  local got=$?
  if [ "$got" = "$want" ]; then
    printf '  ok    %-24s %s\n' "$name" "$got"
    PASS=$((PASS+1))
  else
    printf '  FAIL  %-24s got %s, want %s\n' "$name" "$got" "$want"
    FAIL=$((FAIL+1))
  fi
}

mkdir -p tests
cd tests || exit 1
ln -sf ../dcc dcc 2>/dev/null

# ---------- 基本 ----------
cat > t01.dc << 'EOF'
int main(){
  return 42;
}
EOF
run "return" t01.dc 42

cat > t02.dc << 'EOF'
int main(){
  int a;
  a = 10;
  return a + 5;
}
EOF
run "variable/add" t02.dc 15

cat > t03.dc << 'EOF'
int main(){
  return 20 / 3;
}
EOF
run "divide" t03.dc 6

cat > t04.dc << 'EOF'
int main(){
  return 17 % 5;
}
EOF
run "modulo" t04.dc 2

# ---------- ビット演算 ----------
cat > t05.dc << 'EOF'
int main(){
  return 5 & 3;
}
EOF
run "bit and" t05.dc 1

cat > t06.dc << 'EOF'
int main(){
  return 1 << 3;
}
EOF
run "shift left" t06.dc 8

cat > t07.dc << 'EOF'
int main(){
  return 5 | 2;
}
EOF
run "bit or" t07.dc 7

# ---------- 制御構造 ----------
cat > t08.dc << 'EOF'
int main(){
  int x;
  x = 2;
  if(x == 1){
    return 10;
  }
  else if(x == 2){
    return 20;
  }
  else{
    return 30;
  }
}
EOF
run "else if" t08.dc 20

cat > t09.dc << 'EOF'
int main(){
  int i;
  int sum;
  sum = 0;
  for(i = 0; i < 10; i = i + 1){
    if(i > 5){
      break;
    }
    sum = sum + i;
  }
  return sum;
}
EOF
run "for break" t09.dc 15

cat > t10.dc << 'EOF'
int main(){
  int i;
  int sum;
  sum = 0;
  for(i = 0; i < 10; i = i + 1){
    if(i < 5){
      continue;
    }
    sum = sum + i;
  }
  return sum;
}
EOF
run "for continue" t10.dc 35

cat > t11.dc << 'EOF'
int main(){
  int i;
  i = 0;
  while(i < 100){
    if(i == 7){
      break;
    }
    i = i + 1;
  }
  return i;
}
EOF
run "while break" t11.dc 7

cat > t12.dc << 'EOF'
int main(){
  int i;
  int sum;
  i = 0;
  sum = 0;
  while(i < 10){
    i = i + 1;
    if(i < 6){
      continue;
    }
    sum = sum + i;
  }
  return sum;
}
EOF
run "while continue" t12.dc 40

# ---------- 関数 ----------
cat > t13.dc << 'EOF'
int add(int a, int b){
  return a + b;
}
int main(){
  return add(20, 22);
}
EOF
run "function" t13.dc 42

cat > t14.dc << 'EOF'
int fib(int n){
  if(n < 2){
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}
int main(){
  return fib(10);
}
EOF
run "recursion" t14.dc 55

# ---------- 配列 ----------
cat > t15.dc << 'EOF'
int main(){
  int a[10];
  a[3] = 5;
  return a[3];
}
EOF
run "array" t15.dc 5

# ---------- ポインタ ----------
cat > t16.dc << 'EOF'
int main(){
  int* p;
  p = malloc(10 * sizeof(int));
  p[0] = 42;
  return p[0];
}
EOF
run "malloc/array" t16.dc 42

cat > t17.dc << 'EOF'
int main(){
  int x;
  int* p;
  x = 42;
  p = &x;
  return p[0];
}
EOF
run "address of" t17.dc 42

cat > t18.dc << 'EOF'
int main(){
  int x;
  int* p;
  x = 0;
  p = &x;
  *p = 42;
  return *p;
}
EOF
run "deref" t18.dc 42

cat > t19.dc << 'EOF'
int sum(int* p){
  return p[0] + p[1];
}
int main(){
  int* arr;
  arr = malloc(4 * sizeof(int));
  arr[0] = 10;
  arr[1] = 20;
  return sum(arr);
}
EOF
run "ptr arg" t19.dc 30

cat > t20.dc << 'EOF'
int* makeArray(int n){
  int* p;
  p = malloc(n * sizeof(int));
  p[0] = 42;
  return p;
}
int main(){
  int* arr;
  arr = makeArray(10);
  return arr[0];
}
EOF
run "ptr return" t20.dc 42

cat > t21.dc << 'EOF'
int main(){
  int* p;
  p = malloc(10 * sizeof(int));
  p[0] = 42;
  free(p);
  return 0;
}
EOF
run "free" t21.dc 0

# ---------- sizeof ----------
cat > t22.dc << 'EOF'
int main(){
  return sizeof(int);
}
EOF
run "sizeof int" t22.dc 4

cat > t23.dc << 'EOF'
int main(){
  return sizeof(double);
}
EOF
run "sizeof double" t23.dc 8

cat > t24.dc << 'EOF'
int main(){
  return sizeof(int*);
}
EOF
run "sizeof ptr" t24.dc 8

cat > t25.dc << 'EOF'
class Mixed { char c; int x; }
int main(){
  return sizeof(Mixed);
}
EOF
run "sizeof struct" t25.dc 8

# ---------- 構造体 ----------
cat > t26.dc << 'EOF'
class Point { int x; int y; }
int main(){
  Point p;
  p.x = 3;
  p.y = 4;
  return p.x + p.y;
}
EOF
run "struct member" t26.dc 7

cat > t27.dc << 'EOF'
class Tree {
  int* leaves;
  int depth;
}
int main(){
  Tree t;
  t.leaves = malloc(8 * sizeof(int));
  t.leaves[5] = 42;
  return t.leaves[5];
}
EOF
run "member dyn array" t27.dc 42

cat > t28.dc << 'EOF'
class Node { int key; int value; }
int main(){
  Node nodes[8];
  nodes[3].key = 10;
  return nodes[3].key;
}
EOF
run "array member fixed" t28.dc 10

cat > t29.dc << 'EOF'
class Node { int key; int value; }
int main(){
  Node* nodes;
  nodes = malloc(8 * sizeof(Node));
  nodes[3].value = 99;
  return nodes[3].value;
}
EOF
run "array member dyn" t29.dc 99

cat > t30.dc << 'EOF'
class Node { int key; int value; }
int main(){
  Node* nodes;
  int i;
  nodes = malloc(8 * sizeof(Node));
  for(i = 0; i < 8; i = i + 1){
    nodes[i].key = i * 10;
  }
  return nodes[5].key;
}
EOF
run "array member loop" t30.dc 50

# ---------- 二分木 ----------
cat > t31.dc << 'EOF'
class Tree {
  int depth;
  int size;
  int* leaves;
  int path[10];
}
int main(){
  Tree t;
  int i;
  int addr;
  t.depth = 5;
  t.size = 1 << t.depth;
  t.leaves = malloc(t.size * sizeof(int));
  for(i = 0; i < t.size; i = i + 1){
    t.leaves[i] = 0;
  }
  t.path[0] = 1;
  t.path[1] = 0;
  t.path[2] = 1;
  t.path[3] = 1;
  t.path[4] = 0;
  addr = 0;
  for(i = 0; i < t.depth; i = i + 1){
    addr = (addr << 1) | t.path[i];
  }
  t.leaves[addr] = 42;
  return t.leaves[22];
}
EOF
run "binary tree d5" t31.dc 42

# ---------- コメント ----------
cat > t32.dc << 'EOF'
// line comment
int main(){
  return 42;
}
EOF
run "line comment" t32.dc 42

cat > t33.dc << 'EOF'
/* block
 * comment
 */
int main(){
  return 42;
}
EOF
run "block comment" t33.dc 42

# ---------- import ----------
cat > lib_t34.dc << 'EOF'
int pathToAddr(int* path, int depth){
  int addr;
  int i;
  addr = 0;
  for(i = 0; i < depth; i = i + 1){
    addr = (addr << 1) | path[i];
  }
  return addr;
}
EOF
cat > t34.dc << 'EOF'
import "lib_t34.dc";
int main(){
  int* path;
  path = malloc(5 * sizeof(int));
  path[0] = 1;
  path[1] = 0;
  path[2] = 1;
  path[3] = 1;
  path[4] = 0;
  return pathToAddr(path, 5);
}
EOF
run "import function" t34.dc 22

cat > lib_t35.dc << 'EOF'
class Tree {
  int depth;
  int size;
  int* leaves;
}
EOF
cat > t35.dc << 'EOF'
import "lib_t35.dc";
int main(){
  Tree t;
  t.depth = 5;
  t.size = 1 << t.depth;
  t.leaves = malloc(t.size * sizeof(int));
  t.leaves[22] = 42;
  return t.leaves[22];
}
EOF
run "import struct" t35.dc 42

# ---------- 括弧式 ----------
cat > t36.dc << 'EOF'
int main(){
  return (2 + 3) * 4;
}
EOF
run "paren expr" t36.dc 20

echo ""
echo "=============================="
printf "  pass: %d   fail: %d\n" "$PASS" "$FAIL"
echo "=============================="

cd ..
