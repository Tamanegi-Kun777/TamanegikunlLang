#!/bin/bash
# DummyC 演算子テスト
# 使い方: dummyc-lab で bash test_operators.sh

PASS=0
FAIL=0

run() {
  local name="$1"
  local src="$2"
  local want="$3"
  local f="op_tmp.dc"
  printf '%s' "$src" > "$f"
  rm -f op_tmp.ll
  ./dcc "$f" > /dev/null 2>&1
  if [ ! -f op_tmp.ll ]; then
    printf '  FAIL  %-26s (compile error)\n' "$name"
    FAIL=$((FAIL+1))
    return
  fi
  lli op_tmp.ll > /dev/null 2>&1
  local got=$?
  if [ "$got" = "$want" ]; then
    printf '  ok    %-26s %s\n' "$name" "$got"
    PASS=$((PASS+1))
  else
    printf '  FAIL  %-26s got %s, want %s\n' "$name" "$got" "$want"
    FAIL=$((FAIL+1))
  fi
}

echo "=== 算術演算子 ==="
run "add"        'int main(){ return 20 + 22; }' 42
run "sub"        'int main(){ return 50 - 8; }' 42
run "mul"        'int main(){ return 6 * 7; }' 42
run "div"        'int main(){ return 84 / 2; }' 42
run "div trunc"  'int main(){ return 20 / 3; }' 6
run "mod"        'int main(){ return 17 % 5; }' 2
run "mod zero"   'int main(){ return 20 % 5; }' 0
run "mod big"    'int main(){ return 100 % 7; }' 2
run "neg via sub" 'int main(){ int a; a = 5; return 0 - a + 47; }' 42

echo ""
echo "=== 優先順位 ==="
run "mul before add"  'int main(){ return 2 + 5 * 8; }' 42
run "div before sub"  'int main(){ return 50 - 16 / 2; }' 42
run "mod before add"  'int main(){ return 40 + 17 % 5; }' 42
run "paren override"  'int main(){ return (2 + 5) * 6; }' 42
run "nested paren"    'int main(){ return ((1 + 2) * (3 + 4)) * 2; }' 42
run "left assoc sub"  'int main(){ return 100 - 50 - 8; }' 42
run "left assoc div"  'int main(){ return 168 / 2 / 2; }' 42

echo ""
echo "=== ビット演算子 ==="
run "bit and"     'int main(){ return 5 & 3; }' 1
run "bit or"      'int main(){ return 40 | 2; }' 42
run "bit and mask" 'int main(){ return 255 & 42; }' 42
run "shl"         'int main(){ return 1 << 3; }' 8
run "shl 21"      'int main(){ return 21 << 1; }' 42
run "shr"         'int main(){ return 84 >> 1; }' 42
run "shr 3"       'int main(){ return 64 >> 3; }' 8
run "shift combo" 'int main(){ int a; a = 0; a = (a << 1) | 1; a = (a << 1) | 0; a = (a << 1) | 1; return a; }' 5

echo ""
echo "=== 比較演算子 ==="
run "lt true"   'int main(){ if(3 < 5){ return 1; } return 0; }' 1
run "lt false"  'int main(){ if(5 < 3){ return 1; } return 0; }' 0
run "gt true"   'int main(){ if(5 > 3){ return 1; } return 0; }' 1
run "gt false"  'int main(){ if(3 > 5){ return 1; } return 0; }' 0
run "le equal"  'int main(){ if(5 <= 5){ return 1; } return 0; }' 1
run "le less"   'int main(){ if(3 <= 5){ return 1; } return 0; }' 1
run "le false"  'int main(){ if(5 <= 3){ return 1; } return 0; }' 0
run "ge equal"  'int main(){ if(5 >= 5){ return 1; } return 0; }' 1
run "ge false"  'int main(){ if(3 >= 5){ return 1; } return 0; }' 0
run "eq true"   'int main(){ if(42 == 42){ return 1; } return 0; }' 1
run "eq false"  'int main(){ if(42 == 41){ return 1; } return 0; }' 0
run "ne true"   'int main(){ if(42 != 41){ return 1; } return 0; }' 1
run "ne false"  'int main(){ if(42 != 42){ return 1; } return 0; }' 0

echo ""
echo "=== 論理演算子 ==="
run "and TT"    'int main(){ if(1 && 1){ return 1; } return 0; }' 1
run "and TF"    'int main(){ if(1 && 0){ return 1; } return 0; }' 0
run "and FT"    'int main(){ if(0 && 1){ return 1; } return 0; }' 0
run "and FF"    'int main(){ if(0 && 0){ return 1; } return 0; }' 0
run "or TT"     'int main(){ if(1 || 1){ return 1; } return 0; }' 1
run "or TF"     'int main(){ if(1 || 0){ return 1; } return 0; }' 1
run "or FT"     'int main(){ if(0 || 1){ return 1; } return 0; }' 1
run "or FF"     'int main(){ if(0 || 0){ return 1; } return 0; }' 0
run "not zero"  'int main(){ if(!0){ return 1; } return 0; }' 1
run "not one"   'int main(){ if(!1){ return 1; } return 0; }' 0
run "not var"   'int main(){ int a; a = 0; if(!a){ return 1; } return 0; }' 1
run "return not" 'int main(){ int a; a = 0; return !a; }' 1
run "and cmp"   'int main(){ int a; int b; a = 5; b = 3; if(a > 0 && b > 0){ return 1; } return 0; }' 1
run "or cmp"    'int main(){ int a; a = 0; if(a > 0 || a == 0){ return 1; } return 0; }' 1
run "and chain" 'int main(){ if(1 && 1 && 1){ return 1; } return 0; }' 1
run "or chain"  'int main(){ if(0 || 0 || 1){ return 1; } return 0; }' 1
run "and or mix" 'int main(){ if(0 && 1 || 1){ return 1; } return 0; }' 1

echo ""
echo "=== 短絡評価 ==="
run "and short"  'int main(){ int* p; p = 0; if(p != 0 && p[0] == 5){ return 1; } return 99; }' 99
run "or short"   'int main(){ int* p; p = 0; if(p == 0 || p[0] == 5){ return 1; } return 99; }' 1
run "and div0"   'int main(){ int a; a = 0; if(a != 0 && 100 / a > 5){ return 1; } return 99; }' 99

echo ""
echo "=== 単項演算子 ==="
run "addr deref"  'int main(){ int x; int* p; x = 42; p = &x; return *p; }' 42
run "deref store" 'int main(){ int x; int* p; x = 0; p = &x; *p = 42; return x; }' 42
run "addr index"  'int main(){ int x; int* p; x = 42; p = &x; return p[0]; }' 42
run "not not"     'int main(){ int a; a = 5; return !!a; }' 1

echo ""
echo "=== 代入と複合 ==="
run "assign"       'int main(){ int a; a = 42; return a; }' 42
run "assign expr"  'int main(){ int a; a = 6 * 7; return a; }' 42
run "chain calc"   'int main(){ int a; int b; a = 20; b = 22; return a + b; }' 42
run "self update"  'int main(){ int a; a = 20; a = a + 22; return a; }' 42
run "mixed ops"    'int main(){ int a; a = 3; return a * 8 + 18 % 6 + 18; }' 42

echo ""
echo "=== sizeof ==="
run "sizeof int"    'int main(){ return sizeof(int); }' 4
run "sizeof char"   'int main(){ return sizeof(char); }' 1
run "sizeof double" 'int main(){ return sizeof(double); }' 8
run "sizeof intptr" 'int main(){ return sizeof(int*); }' 8
run "sizeof expr"   'int main(){ return sizeof(int) * 10 + 2; }' 42

rm -f op_tmp.dc op_tmp.ll
echo ""
echo "=============================="
printf "  pass: %d   fail: %d\n" "$PASS" "$FAIL"
echo "=============================="
