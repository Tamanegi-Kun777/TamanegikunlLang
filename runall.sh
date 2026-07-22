#!/bin/bash
# DummyC 全テスト実行
# 使い方: dummyc-lab で bash runall.sh

echo "############################################"
echo "#  DummyC 全テスト"
echo "############################################"
echo ""

# ビルド
echo ">>> ビルド中..."
rm -f dcc
make > /dev/null 2>&1
if [ ! -f dcc ]; then
  echo "!!! ビルド失敗 !!!"
  make 2>&1 | head -10
  exit 1
fi
echo "    OK"
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0

# ---- スクリプト形式のテストを実行 ----
for script in test_operators.sh test_multiarray.sh; do
  if [ -f "$script" ]; then
    echo "############################################"
    echo "#  $script"
    echo "############################################"
    out=$(bash "$script" 2>&1)
    echo "$out" | grep -E "^(===|  FAIL)" 
    line=$(echo "$out" | grep "pass:")
    echo "  $line"
    p=$(echo "$line" | sed 's/.*pass: *\([0-9]*\).*/\1/')
    f=$(echo "$line" | sed 's/.*fail: *\([0-9]*\).*/\1/')
    TOTAL_PASS=$((TOTAL_PASS + p))
    TOTAL_FAIL=$((TOTAL_FAIL + f))
    echo ""
  fi
done

# ---- 個別の機能テスト ----
echo "############################################"
echo "#  機能テスト"
echo "############################################"

check() {
  local name="$1"
  local src="$2"
  local want="$3"
  printf '%s' "$src" > all_tmp.dc
  rm -f all_tmp.ll
  ./dcc all_tmp.dc > /dev/null 2>&1
  if [ ! -f all_tmp.ll ]; then
    printf '  FAIL  %-32s (compile error)\n' "$name"
    TOTAL_FAIL=$((TOTAL_FAIL+1))
    return
  fi
  lli all_tmp.ll > /dev/null 2>&1
  local got=$?
  if [ "$got" = "$want" ]; then
    printf '  ok    %-32s %s\n' "$name" "$got"
    TOTAL_PASS=$((TOTAL_PASS+1))
  else
    printf '  FAIL  %-32s got %s, want %s\n' "$name" "$got" "$want"
    TOTAL_FAIL=$((TOTAL_FAIL+1))
  fi
}

echo ""
echo "--- 基本 ---"
check "return"          'int main(){ return 42; }' 42
check "variable"        'int main(){ int a; a = 42; return a; }' 42
check "char type"       'int main(){ char c; c = 65; return c; }' 65

echo ""
echo "--- 制御構造 ---"
check "if else"         'int main(){ int a; a = 2; if(a == 1){ return 10; } else{ return 42; } }' 42
check "else if"         'int main(){ int a; a = 2; if(a == 1){ return 1; } else if(a == 2){ return 42; } else{ return 3; } }' 42
check "while"           'int main(){ int i; i = 0; while(i < 42){ i = i + 1; } return i; }' 42
check "for"             'int main(){ int i; int s; s = 0; for(i = 0; i < 9; i = i + 1){ s = s + i; } return s; }' 36
check "for range"       'int main(){ int i; int s; s = 0; for(i in range(9)){ s = s + i; } return s; }' 36
check "break"           'int main(){ int i; for(i = 0; i < 100; i = i + 1){ if(i == 42){ break; } } return i; }' 42
check "continue"        'int main(){ int i; int s; s = 0; for(i = 0; i < 10; i = i + 1){ if(i < 5){ continue; } s = s + i; } return s; }' 35

echo ""
echo "--- 関数 ---"
check "function"        'int add(int a, int b){ return a + b; } int main(){ return add(20, 22); }' 42
check "recursion"       'int fib(int n){ if(n < 2){ return n; } return fib(n-1) + fib(n-2); } int main(){ return fib(10); }' 55
check "no args"         'int get(){ return 42; } int main(){ return get(); }' 42
check "three args"      'int f(int a, int b, int c){ return a + b + c; } int main(){ return f(10, 15, 17); }' 42

echo ""
echo "--- 配列 ---"
check "array 1d"        'int main(){ int a[10]; a[3] = 42; return a[3]; }' 42
check "array loop"      'int main(){ int a[5]; int i; int s; for(i = 0; i < 5; i = i + 1){ a[i] = i; } s = 0; for(i = 0; i < 5; i = i + 1){ s = s + a[i]; } return s; }' 10
check "array 2d"        'int main(){ int a[3][4]; a[1][2] = 42; return a[1][2]; }' 42
check "array 3d"        'int main(){ int a[2][3][4]; a[1][2][3] = 42; return a[1][2][3]; }' 42

echo ""
echo "--- ポインタ ---"
check "malloc"          'int main(){ int* p; p = malloc(10 * sizeof(int)); p[0] = 42; return p[0]; }' 42
check "address of"      'int main(){ int x; int* p; x = 42; p = &x; return p[0]; }' 42
check "deref read"      'int main(){ int x; int* p; x = 42; p = &x; return *p; }' 42
check "deref write"     'int main(){ int x; int* p; x = 0; p = &x; *p = 42; return x; }' 42
check "ptr arg"         'int sum(int* p){ return p[0] + p[1]; } int main(){ int* a; a = malloc(4 * sizeof(int)); a[0] = 20; a[1] = 22; return sum(a); }' 42
check "ptr return"      'int* mk(int n){ int* p; p = malloc(n * sizeof(int)); p[0] = 42; return p; } int main(){ int* a; a = mk(4); return a[0]; }' 42
check "free"            'int main(){ int* p; p = malloc(10 * sizeof(int)); free(p); return 0; }' 0
check "null compare"    'int main(){ int* p; p = 0; if(p == 0){ return 42; } return 0; }' 42

echo ""
echo "--- 構造体 ---"
check "struct member"   'class P { int x; int y; } int main(){ P p; p.x = 20; p.y = 22; return p.x + p.y; }' 42
check "struct array"    'class N { int k; int v; } int main(){ N a[8]; a[3].k = 42; return a[3].k; }' 42
check "struct dynarray" 'class N { int k; int v; } int main(){ N* a; a = malloc(8 * sizeof(N)); a[3].v = 42; return a[3].v; }' 42
check "member array"    'class T { int* leaves; } int main(){ T t; t.leaves = malloc(8 * sizeof(int)); t.leaves[5] = 42; return t.leaves[5]; }' 42
check "nested 2"        'class I { int v; } class O { I in; } int main(){ O o; o.in.v = 42; return o.in.v; }' 42
check "nested 3"        'class A { int v; } class B { A a; } class C { B b; } int main(){ C c; c.b.a.v = 42; return c.b.a.v; }' 42
check "nested rhs"      'class I { int v; } class O { I in; } int main(){ O o; int x; o.in.v = 42; x = o.in.v; return x; }' 42
check "sizeof struct"   'class M { char c; int x; } int main(){ return sizeof(M); }' 8

echo ""
echo "--- enum / match ---"
check "enum"            'enum Color { Red, Green, Blue } int main(){ int c; c = Green; return c; }' 1
check "match"           'enum Color { Red, Green, Blue } int main(){ int c; c = Blue; match c { Red => return 1; Green => return 2; Blue => return 42; } return 0; }' 42

echo ""
echo "--- コメント ---"
check "line comment"    'int main(){ // comment
  return 42; }' 42
check "block comment"   'int main(){ /* multi
  line */ return 42; }' 42

echo ""
echo "--- sizeof ---"
check "sizeof int"      'int main(){ return sizeof(int); }' 4
check "sizeof char"     'int main(){ return sizeof(char); }' 1
check "sizeof double"   'int main(){ return sizeof(double); }' 8
check "sizeof ptr"      'int main(){ return sizeof(int*); }' 8

rm -f all_tmp.dc all_tmp.ll

echo ""
echo "############################################"
printf "#  合計   pass: %d   fail: %d\n" "$TOTAL_PASS" "$TOTAL_FAIL"
echo "############################################"
