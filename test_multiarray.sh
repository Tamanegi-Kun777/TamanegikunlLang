#!/bin/bash
# DummyC 多次元配列テスト
# 使い方: dummyc-lab で bash test_multiarray.sh

PASS=0
FAIL=0

run() {
  local name="$1"
  local src="$2"
  local want="$3"
  local f="ma_tmp.dc"
  printf '%s' "$src" > "$f"
  rm -f ma_tmp.ll
  ./dcc "$f" > /dev/null 2>&1
  if [ ! -f ma_tmp.ll ]; then
    printf '  FAIL  %-30s (compile error)\n' "$name"
    FAIL=$((FAIL+1))
    return
  fi
  lli ma_tmp.ll > /dev/null 2>&1
  local got=$?
  if [ "$got" = "$want" ]; then
    printf '  ok    %-30s %s\n' "$name" "$got"
    PASS=$((PASS+1))
  else
    printf '  FAIL  %-30s got %s, want %s\n' "$name" "$got" "$want"
    FAIL=$((FAIL+1))
  fi
}

echo "=== 宣言 ==="
run "declare 2d"    'int main(){ int a[3][4]; return 0; }' 0
run "declare 3d"    'int main(){ int a[2][3][4]; return 0; }' 0
run "declare 4d"    'int main(){ int a[2][2][2][2]; return 0; }' 0
run "declare 1d"    'int main(){ int a[10]; return 0; }' 0
run "declare char"  'int main(){ char c[3][4]; return 0; }' 0

echo ""
echo "=== 基本の読み書き ==="
run "write read 2d"  'int main(){ int a[3][4]; a[1][2] = 42; return a[1][2]; }' 42
run "write read 3d"  'int main(){ int a[2][3][4]; a[1][2][3] = 42; return a[1][2][3]; }' 42
run "write read 4d"  'int main(){ int a[2][2][2][2]; a[1][1][1][1] = 42; return a[1][1][1][1]; }' 42
run "first element"  'int main(){ int a[3][4]; a[0][0] = 7; return a[0][0]; }' 7
run "last element"   'int main(){ int a[3][4]; a[2][3] = 9; return a[2][3]; }' 9
run "overwrite"      'int main(){ int a[2][2]; a[1][1] = 5; a[1][1] = 42; return a[1][1]; }' 42

echo ""
echo "=== 独立性（他の要素を壊さない）==="
run "two elements"   'int main(){ int a[2][2]; a[0][0] = 10; a[1][1] = 32; return a[0][0] + a[1][1]; }' 42
run "row boundary"   'int main(){ int a[2][3]; a[0][2] = 1; a[1][0] = 2; return a[0][2] * 10 + a[1][0]; }' 12
run "no overlap"     'int main(){ int a[3][3]; a[1][1] = 5; a[0][0] = 0; a[2][2] = 0; return a[1][1]; }' 5
run "all distinct"   'int main(){ int a[2][2]; a[0][0] = 1; a[0][1] = 2; a[1][0] = 4; a[1][1] = 8; return a[0][0] + a[0][1] + a[1][0] + a[1][1]; }' 15

echo ""
echo "=== 変数の添字 ==="
run "var index"      'int main(){ int a[3][4]; int i; int j; i = 1; j = 2; a[i][j] = 42; return a[i][j]; }' 42
run "expr index"     'int main(){ int a[3][4]; a[1 + 1][1 + 2] = 42; return a[2][3]; }' 42
run "mixed index"    'int main(){ int a[3][4]; int i; i = 1; a[i][i + 1] = 42; return a[1][2]; }' 42

echo ""
echo "=== ループ ==="
run "fill and sum"   'int main(){ int a[3][4]; int i; int j; int s; s = 0; for(i = 0; i < 3; i = i + 1){ for(j = 0; j < 4; j = j + 1){ a[i][j] = i * 4 + j; } } for(i = 0; i < 3; i = i + 1){ for(j = 0; j < 4; j = j + 1){ s = s + a[i][j]; } } return s; }' 66
run "diagonal"       'int main(){ int m[3][3]; int i; int j; int t; for(i = 0; i < 3; i = i + 1){ for(j = 0; j < 3; j = j + 1){ m[i][j] = i * 3 + j + 1; } } t = 0; for(i = 0; i < 3; i = i + 1){ t = t + m[i][i]; } return t; }' 15
run "row sum"        'int main(){ int a[3][4]; int i; int j; int s; for(i = 0; i < 3; i = i + 1){ for(j = 0; j < 4; j = j + 1){ a[i][j] = 1; } } s = 0; for(j = 0; j < 4; j = j + 1){ s = s + a[1][j]; } return s; }' 4
run "col sum"        'int main(){ int a[3][4]; int i; int j; int s; for(i = 0; i < 3; i = i + 1){ for(j = 0; j < 4; j = j + 1){ a[i][j] = 2; } } s = 0; for(i = 0; i < 3; i = i + 1){ s = s + a[i][2]; } return s; }' 6
run "3d loop"        'int main(){ int a[2][2][2]; int i; int j; int k; int s; for(i = 0; i < 2; i = i + 1){ for(j = 0; j < 2; j = j + 1){ for(k = 0; k < 2; k = k + 1){ a[i][j][k] = 1; } } } s = 0; for(i = 0; i < 2; i = i + 1){ for(j = 0; j < 2; j = j + 1){ for(k = 0; k < 2; k = k + 1){ s = s + a[i][j][k]; } } } return s; }' 8

echo ""
echo "=== 式の中での使用 ==="
run "in add"         'int main(){ int a[2][2]; a[0][0] = 20; a[1][1] = 22; return a[0][0] + a[1][1]; }' 42
run "in mul"         'int main(){ int a[2][2]; a[0][0] = 6; a[1][1] = 7; return a[0][0] * a[1][1]; }' 42
run "in condition"   'int main(){ int a[2][2]; a[1][1] = 5; if(a[1][1] > 3){ return 42; } return 0; }' 42
run "as index"       'int main(){ int a[3][3]; int b[5]; a[0][0] = 2; b[2] = 42; return b[a[0][0]]; }' 42
run "in while"       'int main(){ int a[2][2]; int i; a[0][0] = 3; i = 0; while(i < a[0][0]){ i = i + 1; } return i; }' 3
run "assign to var"  'int main(){ int a[2][2]; int x; a[1][0] = 42; x = a[1][0]; return x; }' 42
run "chained assign" 'int main(){ int a[2][2]; a[0][0] = 42; a[1][1] = a[0][0]; return a[1][1]; }' 42

echo ""
echo "=== 1次元との共存 ==="
run "1d still works" 'int main(){ int a[10]; a[5] = 42; return a[5]; }' 42
run "1d and 2d"      'int main(){ int a[10]; int b[3][3]; a[5] = 20; b[1][1] = 22; return a[5] + b[1][1]; }' 42
run "1d loop"        'int main(){ int a[5]; int i; int s; s = 0; for(i = 0; i < 5; i = i + 1){ a[i] = i; } for(i = 0; i < 5; i = i + 1){ s = s + a[i]; } return s; }' 10

echo ""
echo "=== 非対称な次元 ==="
run "wide"           'int main(){ int a[2][10]; a[1][9] = 42; return a[1][9]; }' 42
run "tall"           'int main(){ int a[10][2]; a[9][1] = 42; return a[9][1]; }' 42
run "stride check"   'int main(){ int a[2][10]; a[0][0] = 1; a[1][0] = 42; return a[1][0]; }' 42
run "stride check2"  'int main(){ int a[10][2]; a[0][1] = 1; a[1][0] = 42; return a[1][0]; }' 42

rm -f ma_tmp.dc ma_tmp.ll
echo ""
echo "=============================="
printf "  pass: %d   fail: %d\n" "$PASS" "$FAIL"
echo "=============================="
