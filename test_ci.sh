#!/bin/bash
# 複合代入・インクリメントのテスト
# 使い方: dummyc-lab に置いて  bash test_ci.sh

P=0
F=0

check(){
  local name="$1"
  local want="$2"
  rm -f ci.ll
  ./dcc ci.dc > /dev/null 2>&1
  if [ ! -f ci.ll ]; then
    printf '  FAIL  %-18s (compile error)\n' "$name"
    F=$((F+1))
    return
  fi
  lli ci.ll > /dev/null 2>&1
  local g=$?
  if [ "$g" = "$want" ]; then
    printf '  ok    %-18s %s\n' "$name" "$g"
    P=$((P+1))
  else
    printf '  FAIL  %-18s got %s want %s\n' "$name" "$g" "$want"
    F=$((F+1))
  fi
}

printf 'int main(){\n  int i;\n  i = 41;\n  i++;\n  return i;\n}\n' > ci.dc
check "i++" 42

printf 'int main(){\n  int i;\n  i = 43;\n  i--;\n  return i;\n}\n' > ci.dc
check "i--" 42

printf 'int main(){\n  int i;\n  i = 40;\n  i += 2;\n  return i;\n}\n' > ci.dc
check "+=" 42

printf 'int main(){\n  int i;\n  i = 50;\n  i -= 8;\n  return i;\n}\n' > ci.dc
check "-=" 42

printf 'int main(){\n  int i;\n  i = 6;\n  i *= 7;\n  return i;\n}\n' > ci.dc
check "*=" 42

printf 'int main(){\n  int i;\n  i = 84;\n  i /= 2;\n  return i;\n}\n' > ci.dc
check "/=" 42

printf 'int main(){\n  int i;\n  i = 17;\n  i %%= 5;\n  return i;\n}\n' > ci.dc
check "%=" 2

printf 'int main(){\n  int i;\n  int s;\n  s = 0;\n  for(i = 0; i < 10; i++){\n    s += i;\n  }\n  return s;\n}\n' > ci.dc
check "for i++" 45

printf 'int main(){\n  int i;\n  int c;\n  c = 0;\n  for(i = 10; i > 0; i--){\n    c++;\n  }\n  return c;\n}\n' > ci.dc
check "for i--" 10

printf 'int main(){\n  int i;\n  int j;\n  int c;\n  c = 0;\n  for(i = 0; i < 6; i++){\n    for(j = 0; j < 7; j++){\n      c++;\n    }\n  }\n  return c;\n}\n' > ci.dc
check "nested for" 42

printf 'int main(){\n  int i;\n  i = 0;\n  i += 10;\n  i += 12;\n  i += 20;\n  return i;\n}\n' > ci.dc
check "chained +=" 42

printf 'int main(){\n  int i;\n  i = 20;\n  i += 20 + 2;\n  return i;\n}\n' > ci.dc
check "expr rhs" 42

rm -f ci.dc ci.ll
echo ""
printf "  pass: %d   fail: %d\n" "$P" "$F"
