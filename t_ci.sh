P=0; F=0
t(){ printf '%s' "$2" > ci.dc; rm -f ci.ll; ./dcc ci.dc >/dev/null 2>&1
  if [ ! -f ci.ll ]; then printf '  FAIL  %-20s (compile error)\n' "$1"; F=$((F+1)); return; fi
  lli ci.ll >/dev/null 2>&1; g=$?
  if [ "$g" = "$3" ]; then printf '  ok    %-20s %s\n' "$1" "$g"; P=$((P+1))
  else printf '  FAIL  %-20s got %s want %s\n' "$1" "$g" "$3"; F=$((F+1)); fi; }

t "i++"      'int main(){
  int i;
  i = 41;
  i++;
  return i;
}' 42
t "i--"      'int main(){
  int i;
  i = 43;
  i--;
  return i;
}' 42
t "+="       'int main(){
  int i;
  i = 40;
  i += 2;
  return i;
}' 42
t "-="       'int main(){
  int i;
  i = 50;
  i -= 8;
  return i;
}' 42
t "*="       'int main(){
  int i;
  i = 6;
  i *= 7;
  return i;
}' 42
t "/="       'int main(){
  int i;
  i = 84;
  i /= 2;
  return i;
}' 42
t "%="       'int main(){
  int i;
  i = 17;
  i %= 5;
  return i;
}' 2
t "for i++"  'int main(){
  int i;
  int s;
  s = 0;
  for(i = 0; i < 10; i++){
    s += i;
  }
  return s;
}' 45
t "for i--"  'int main(){
  int i;
  int c;
  c = 0;
  for(i = 10; i > 0; i--){
    c++;
  }
  return c;
}' 10
t "nested"   'int main(){
  int i;
  int j;
  int c;
  c = 0;
  for(i = 0; i < 6; i++){
    for(j = 0; j < 7; j++){
      c++;
    }
  }
  return c;
}' 42
t "chained"  'int main(){
  int i;
  i = 0;
  i += 10;
  i += 12;
  i += 20;
  return i;
}' 42
t "expr rhs" 'int main(){
  int i;
  i = 20;
  i += 20 + 2;
  return i;
}' 42
rm -f ci.dc ci.ll
echo ""; printf "  pass: %d   fail: %d\n" "$P" "$F"
