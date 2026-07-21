#ifndef AST_HPP
#define AST_HPP


#include <string>
#include <map>
#include <vector>
#include "llvm/Support/Casting.h"
#include "APP.hpp"

enum AstID
{
  BaseID,
  VariableDeclID,
  BinaryExprID,
  NullExprID,
  CallExprID,
  JumpStmtID,
  VariableID,
  NumberID,
  FloatNumberID,
  IfStmtID,
  WhileStmtID,
  ForStmtID,
  StructDeclID,
  MemberAccessID,
  ArrayAccessID,
  StringLiteralID,
  EnumValueID,
  MemberArrayAccessID,
  SizeofID,
  ArrayMemberAccessID,
  BreakStmtID,
  ContinueStmtID,
  AddressOfID,
  DerefID,
  LogicalExprID,
  NotExprID,
  ChainMemberAccessID
};

// ファイルの、先頭あたりに、追加
class PrototypeAST;
class FunctionAST;
class FunctionStmtAST;
/*
 *   ASTの基底クラス
 */
class BaseAST
{
  AstID ID;

public:
  BaseAST(AstID id) : ID(id){};
  virtual ~BaseAST(){};
  AstID getValueID() const {return ID;};
};

// ; を示すAST
class NullExprAST : public BaseAST
{
public:
  NullExprAST() : BaseAST(NullExprID){}

  static inline bool classof(NullExprAST const*){return true;}

  static inline bool classof(BaseAST const* base){
    return base->getValueID() == NullExprID;
  }
};

/*
 *   変数宣言を表すAST
 */
class VariableDeclAST : public BaseAST
{
public:
  typedef enum{
    param,
    local
  }DeclType;

private:
  std::string Name;
  std::string TypeName;
  DeclType Type;
  int ArraySize;
  std::vector<int> ArrayDims;
public:
  VariableDeclAST(const std::string &name, const std::string &type_name = "int") : BaseAST(VariableDeclID), Name(name), TypeName(type_name), ArraySize(0){};

  // VariableDeclASTなのでtrueを返す
  static inline bool classof(VariableDeclAST const*){return true;};

  // 渡されたBaseASTクラスがVariableDeclASTか判定する
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == VariableDeclID;
  };

  ~VariableDeclAST(){};

  // 変数名を取得する
  std::string getName(){return Name;};
  std::string getTypeName(){return TypeName;};
  int getArraySize(){return ArraySize;};
  void setArraySize(int size){ArraySize = size;};
  void addArrayDim(int size){ArrayDims.push_back(size);};
  int getArrayDimNum(){return ArrayDims.size();};
  int getArrayDim(int i){return ArrayDims[i];};
  // 変数の宣言種別を設定する
  bool setDeclType(DeclType type){
    Type = type;
    return true;
  };

  // 変数の宣言種別を取得する
  DeclType getType(){return Type;};
};

/*
 *   二項演算を表すAST
 */
class BinaryExprAST : public BaseAST
{
  std::string Op;
  BaseAST *LHS, *RHS;

public:
  BinaryExprAST(std::string op, BaseAST *lhs, BaseAST *rhs) : BaseAST(BinaryExprID), Op(op), LHS(lhs), RHS(rhs){};

  ~BinaryExprAST(){SAFE_DELETE(LHS); SAFE_DELETE(RHS);};

  // BinaryExprASTなのでtrueを返す
  static inline bool classof(BinaryExprAST const*){return true;};

  // 渡されたBaseASTがBinaryExprASTか判定する
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == BinaryExprID;
  };

  // 演算子を取得する
  std::string getOp(){return Op;};

  // 左辺値を取得する
  BaseAST *getLHS(){return LHS;};

  // 右辺値を取得する
  BaseAST *getRHS(){return RHS;};
};

/*
 *  関数呼び出しを表すAST
 */
class CallExprAST : public BaseAST
{
  std::string Callee;
  std::vector<BaseAST*> Args;

public:
  CallExprAST(const std::string &callee, std::vector<BaseAST*> &args)
    : BaseAST(CallExprID), Callee(callee), Args(args){};

  ~CallExprAST();

  // CallExprASTなのでtrueを返す
  static inline bool classof(CallExprAST const*){return true;};

  // 渡されたBaseASTがCallExprASTなのか判定する
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == CallExprID;
  };

  // 呼び出す関数名を取得する
  std::string getCallee(){return Callee;};

  // i番目の引数を取得する
  BaseAST *getArgs(int i){
    if(i<Args.size()){
      return Args.at(i);
    }
    else{
      return NULL;
    }
  };
};
/*
 *  ジャンプ（ここではreturn）を表すAST
 */
class JumpStmtAST : public BaseAST
{
  BaseAST *Expr;

public:
  JumpStmtAST(BaseAST *expr) : BaseAST(JumpStmtID), Expr(expr){};

  ~JumpStmtAST(){SAFE_DELETE(Expr);};

  static inline bool classof(JumpStmtAST const*){return true;};

  static inline bool classof(BaseAST const* base){
    return base->getValueID() == JumpStmtID;
  };

  BaseAST *getExpr(){return Expr;};
};
/*
 *  if文を表すAST
 */
class IfStmtAST : public BaseAST
{
  BaseAST *Condition;
  std::vector<BaseAST*> ThenStmts;
  std::vector<BaseAST*> ElseStmts;
public:
  IfStmtAST(BaseAST *condition) : BaseAST(IfStmtID), Condition(condition){};
  ~IfStmtAST(){SAFE_DELETE(Condition);};
  static inline bool classof(IfStmtAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == IfStmtID;
  };
  BaseAST *getCondition(){return Condition;};
  bool addThenStmt(BaseAST *stmt){ThenStmts.push_back(stmt); return true;};
  bool addElseStmt(BaseAST *stmt){ElseStmts.push_back(stmt); return true;};
  BaseAST *getThenStmt(int i){
    if(i < ThenStmts.size()){ return ThenStmts.at(i); }
    else{ return NULL; }
  };
  BaseAST *getElseStmt(int i){
    if(i < ElseStmts.size()){ return ElseStmts.at(i); }
    else{ return NULL; }
  };
};
/*
 *  while文を表すAST
 */
class WhileStmtAST : public BaseAST
{
  BaseAST *Condition;
  std::vector<BaseAST*> BodyStmts;
public:
  WhileStmtAST(BaseAST *condition) : BaseAST(WhileStmtID), Condition(condition){};
  ~WhileStmtAST(){SAFE_DELETE(Condition);};
  static inline bool classof(WhileStmtAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == WhileStmtID;
  };
  BaseAST *getCondition(){return Condition;};
  bool addBodyStmt(BaseAST *stmt){BodyStmts.push_back(stmt); return true;};
  BaseAST *getBodyStmt(int i){
    if(i < BodyStmts.size()){ return BodyStmts.at(i); }
    else{ return NULL; }
  };
};
/*
 *  for文を表すAST
 */
class ForStmtAST : public BaseAST
{
  BaseAST *Init;
  BaseAST *Condition;
  BaseAST *Update;
  std::vector<BaseAST*> BodyStmts;
public:
  ForStmtAST(BaseAST *init, BaseAST *condition, BaseAST *update)
    : BaseAST(ForStmtID), Init(init), Condition(condition), Update(update){};
  ~ForStmtAST(){
    SAFE_DELETE(Init);
    SAFE_DELETE(Condition);
    SAFE_DELETE(Update);
  };
  static inline bool classof(ForStmtAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == ForStmtID;
  };
  BaseAST *getInit(){return Init;};
  BaseAST *getCondition(){return Condition;};
  BaseAST *getUpdate(){return Update;};
  bool addBodyStmt(BaseAST *stmt){BodyStmts.push_back(stmt); return true;};
  BaseAST *getBodyStmt(int i){
    if(i < BodyStmts.size()){ return BodyStmts.at(i); }
    else{ return NULL; }
  };
};
/*
 *  構造体定義を表すAST
 */
class StructDeclAST : public BaseAST
{
  std::string Name;
  std::vector<std::string> MemberNames;
  std::vector<std::string> MemberTypes;
  std::vector<int> MemberArraySizes;   // 0なら配列でない
  std::vector<FunctionAST*> Methods;
public:
  StructDeclAST(const std::string &name) : BaseAST(StructDeclID), Name(name){};
  ~StructDeclAST(){};
  static inline bool classof(StructDeclAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == StructDeclID;
  };
  std::string getName(){return Name;};
  bool addMember(const std::string &member_name, const std::string &member_type, int array_size = 0){
    MemberNames.push_back(member_name);
    MemberTypes.push_back(member_type);
    MemberArraySizes.push_back(array_size);
    return true;
  };

  int getMemberNum(){return MemberNames.size();};
  std::string getMemberName(int i){
    if(i < MemberNames.size()){ return MemberNames.at(i); }
    else{ return ""; }
  };
  std::string getMemberType(int i){
    if(i < MemberTypes.size()){ return MemberTypes.at(i); }
    else{ return ""; }
  };
  int getMemberArraySize(int i){
    if(i < MemberArraySizes.size()){ return MemberArraySizes.at(i); }
    else{ return 0; }
  };
  bool addMethod(FunctionAST *method){Methods.push_back(method); return true;};
  int getMethodNum(){return Methods.size();};
  FunctionAST *getMethod(int i){
    if(i < Methods.size()){ return Methods.at(i); }
    else{ return NULL; }
  };
};
/*
 *  メンバアクセス(p.x)を表すAST
 */
class MemberAccessAST : public BaseAST
{
  std::string VariableName;
  std::string MemberName;
  bool IsCall;
public:
   MemberAccessAST(const std::string &var_name, const std::string &member_name, bool is_call = false)
    : BaseAST(MemberAccessID), VariableName(var_name), MemberName(member_name), IsCall(is_call){};
  ~MemberAccessAST(){};
  static inline bool classof(MemberAccessAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == MemberAccessID;
  };
  std::string getVariableName(){return VariableName;};
  std::string getMemberName(){return MemberName;};
  bool getIsCall(){return IsCall;};
};
/*
 *  構造体メンバの配列アクセス t.leaves[5] を表すAST
 */
class MemberArrayAccessAST : public BaseAST
{
  std::string VariableName;
  std::string MemberName;
  BaseAST *Index;
public:
  MemberArrayAccessAST(const std::string &var_name, const std::string &member_name, BaseAST *index)
    : BaseAST(MemberArrayAccessID), VariableName(var_name), MemberName(member_name), Index(index){};
  //~MemberArrayAccessAST(){SAFE_DELETE(Index);};
  ~MemberArrayAccessAST(){};
  static inline bool classof(MemberArrayAccessAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == MemberArrayAccessID;
  };
  std::string getVariableName(){return VariableName;};
  std::string getMemberName(){return MemberName;};
  BaseAST *getIndex(){return Index;};
};
class ArrayMemberAccessAST : public BaseAST
{
  std::string ArrayName;
  BaseAST *Index;
  std::string MemberName;
public:
  ArrayMemberAccessAST(const std::string &array_name, BaseAST *index, const std::string &member_name)
    : BaseAST(ArrayMemberAccessID), ArrayName(array_name), Index(index), MemberName(member_name){};
  ~ArrayMemberAccessAST(){};
  static inline bool classof(ArrayMemberAccessAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == ArrayMemberAccessID;
  };
  std::string getArrayName(){return ArrayName;};
  BaseAST *getIndex(){return Index;};
  std::string getMemberName(){return MemberName;};
};
/*
 *  break文を表すAST
 */
class BreakStmtAST : public BaseAST
{
public:
  BreakStmtAST() : BaseAST(BreakStmtID){};
  ~BreakStmtAST(){};
  static inline bool classof(BreakStmtAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == BreakStmtID;
  };
};
/*
 *  continue文を表すAST
 */
class ContinueStmtAST : public BaseAST
{
public:
  ContinueStmtAST() : BaseAST(ContinueStmtID){};
  ~ContinueStmtAST(){};
  static inline bool classof(ContinueStmtAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == ContinueStmtID;
  };
};
/*
 *  sizeof(型) を表すAST
 */
class SizeofAST : public BaseAST
{
  std::string TypeName;
public:
  SizeofAST(const std::string &type_name)
    : BaseAST(SizeofID), TypeName(type_name){};
  ~SizeofAST(){};
  static inline bool classof(SizeofAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == SizeofID;
  };
  std::string getTypeName(){return TypeName;};
};
/*
 *  アドレス参照（&aなど）を表すAST
 */
class AddressOfAST : public BaseAST
{
  std::string VariableName;
public:
  AddressOfAST(const std::string &var_name)
    : BaseAST(AddressOfID), VariableName(var_name){};
  ~AddressOfAST(){};
  static inline bool classof(AddressOfAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == AddressOfID;
  };
  std::string getVariableName(){return VariableName;};
};
/*
 *  参照外し *p を表すAST
 */
class DerefAST : public BaseAST
{
  std::string VariableName;
public:
  DerefAST(const std::string &var_name)
    : BaseAST(DerefID), VariableName(var_name){};
  ~DerefAST(){};
  static inline bool classof(DerefAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == DerefID;
  };
  std::string getVariableName(){return VariableName;};
};
/*
 *  論理演算 && || を表すAST（短絡評価）
 */
class LogicalExprAST : public BaseAST
{
  std::string Op;
  BaseAST *LHS, *RHS;
public:
  LogicalExprAST(const std::string &op, BaseAST *lhs, BaseAST *rhs)
    : BaseAST(LogicalExprID), Op(op), LHS(lhs), RHS(rhs){};
  ~LogicalExprAST(){};
  static inline bool classof(LogicalExprAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == LogicalExprID;
  };
  std::string getOp(){return Op;};
  BaseAST *getLHS(){return LHS;};
  BaseAST *getRHS(){return RHS;};
};
/*
 *  論理否定 ! を表すAST
 */
class NotExprAST : public BaseAST
{
  BaseAST *Expr;
public:
  NotExprAST(BaseAST *expr)
    : BaseAST(NotExprID), Expr(expr){};
  ~NotExprAST(){};
  static inline bool classof(NotExprAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == NotExprID;
  };
  BaseAST *getExpr(){return Expr;};
};
class ChainMemberAccessAST : public BaseAST {
  std::string VariableName;
  std::vector<std::string> Members;

public:
  ChainMemberAccessAST(const std::string &var_name)
    : BaseAST(ChainMemberAccessID), VariableName(var_name){};
  ~ChainMemberAccessAST(){};

  static inline bool classof(ChainMemberAccessAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == ChainMemberAccessID;
  };

  void addMember(const std::string &member){Members.push_back(member);};
  std::string getVariableName(){return VariableName;};
  int getMemberNum(){return Members.size();};
  std::string getMember(int i){return Members[i];};
};
/*
 *  配列要素アクセス(a[3])を表すAST
 */
class ArrayAccessAST : public BaseAST
{
  std::string ArrayName;
  BaseAST *Index;
public:
  ArrayAccessAST(const std::string &name, BaseAST *index)
    : BaseAST(ArrayAccessID), ArrayName(name), Index(index){};
  ~ArrayAccessAST(){};
  static inline bool classof(ArrayAccessAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == ArrayAccessID;
  };
  std::string getArrayName(){return ArrayName;};
  BaseAST *getIndex(){return Index;};
};
/*
 *  文字列リテラル "Hello" を表すAST
 */
class StringLiteralAST : public BaseAST
{
  std::string Str;
public:
  StringLiteralAST(const std::string &str)
    : BaseAST(StringLiteralID), Str(str){};
  ~StringLiteralAST(){};
  static inline bool classof(StringLiteralAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == StringLiteralID;
  };
  std::string getStr(){return Str;};
};
/*
 *  enumバリアントの値 Circle{ 10 } を表すAST
 */
class EnumValueAST : public BaseAST
{
  std::string VariantName;
  int Tag;
  std::vector<BaseAST*> Values;
public:
  EnumValueAST(const std::string &variant_name, int tag)
    : BaseAST(EnumValueID), VariantName(variant_name), Tag(tag){};
  ~EnumValueAST(){};
  static inline bool classof(EnumValueAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == EnumValueID;
  };
  std::string getVariantName(){return VariantName;};
  int getTag(){return Tag;};
  bool addValue(BaseAST *val){Values.push_back(val); return true;};
  int getValueNum(){return Values.size();};
  BaseAST *getValue(int i){
    if(i < Values.size()){ return Values.at(i); }
    else{ return NULL; }
  };
};
/*
 *  変数参照を表すAST
 */

class VariableAST : public BaseAST
{
  std::string Name;

public:
  VariableAST(const std::string &name) : BaseAST(VariableID), Name(name){};

  ~VariableAST(){};

  // VariableASTなのでtrueを返す
  static inline bool classof(VariableAST const*){return true;};

  // 渡されたBAせASTがVariableASTなのか判定する
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == VariableID;
  };

  // 変数名を取得する
  std::string getName(){return Name;};
};

/*
 *  整数を表すAST
 */

class NumberAST : public BaseAST
{
  int Val;

public:
  NumberAST(int val) : BaseAST(NumberID), Val(val){};

  ~NumberAST(){};

  //NumberASTなのでtrueを返す
  static inline bool classof(NumberAST const*){return true;};

  //渡されたBaseASTがNumberASTか判定する
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == NumberID;
  };

  //このASTは表現する値を取得する
  int getNumberValue(){return Val;};
};
/*
 *  浮動小数点数を表すAST
 */
class FloatNumberAST : public BaseAST
{
  double Val;
public:
  FloatNumberAST(double val) : BaseAST(FloatNumberID), Val(val){};
  ~FloatNumberAST(){};
  static inline bool classof(FloatNumberAST const*){return true;};
  static inline bool classof(BaseAST const* base){
    return base->getValueID() == FloatNumberID;
  };
  double getValue(){return Val;};
};
/*
 *  ソースコードを表すAST
 */
class TranslationUnitAST
{
  std::vector<PrototypeAST*> Prototypes;
  std::vector<FunctionAST*> Functions;
  std::vector<StructDeclAST*> Structs;

public:
  TranslationUnitAST(){};
  ~TranslationUnitAST();

  //モジュールにプロトタイプ宣言を追加する
  bool addPrototype(PrototypeAST *proto);

  //モジュールに関数を追加する
  bool addFunction(FunctionAST *func);
  //モジュールに構造体定義を追加する
  bool addStruct(StructDeclAST *s){Structs.push_back(s); return true;}
  //モジュールが空か判定する
  bool empty();

  //i番目のプロトタイプ宣言を取得する
  PrototypeAST *getPrototype(int i){
    if(i < Prototypes.size()){
      return Prototypes.at(i);
    }
    else{
      return NULL;
    }
  }

  //i番目の関数を取得する
  FunctionAST *getFunction(int i){
    if(i < Functions.size()){
      return Functions.at(i);
    }
    else{
      return NULL;
    }
  }
  //i番目の構造体定義を取得する
  StructDeclAST *getStruct(int i){
    if(i < Structs.size()){
      return Structs.at(i);
    }
    else{
      return NULL;
    }
  }
};

/*
 *  関数宣言を表すAST
 */
class PrototypeAST
{
  std::string Name;
  std::vector<std::string> Params;
  std::string RetType;
  std::vector<std::string> ParamTypes;
public:
  PrototypeAST(const std::string &name, const std::vector<std::string> &params)
    : Name(name), Params(params), RetType("int"){};

  //関数名を取得する
  std::string getName(){return Name;};

  //i番目の引数名を取得する
  std::string getParamName(int i){
    if(i < Params.size()){
      return Params.at(i);
    }
    else{
      return NULL;
    }
  }
  ;
  //引数の数を取得する
  int getParamNum(){return Params.size();};
  std::string getRetType(){return RetType;};
  void setRetType(const std::string &t){RetType = t;};
  std::string getParamType(int i){
    if(i < ParamTypes.size()){ return ParamTypes.at(i); }
    else{ return "int"; }
  };
  void addParamType(const std::string &t){ParamTypes.push_back(t);};
};

/*
 *  関数定義を表すAST
 */
class FunctionAST
{
  PrototypeAST *Proto;
  FunctionStmtAST *Body;

public:
  FunctionAST(PrototypeAST *proto, FunctionStmtAST * body) : Proto(proto), Body(body){};

  ~FunctionAST();
  //関数名を取得する
  std::string getName(){return Proto->getName();};
  
  //この関数のプロトタイプ宣言を取得する
  PrototypeAST *getPrototype(){return Proto;};
  
  //この関数のボディを取得する
  FunctionStmtAST *getBody(){return Body;};
};

/*
 *  関数定義（ボディ）を表すAST
 */

class FunctionStmtAST
{
  std::vector<VariableDeclAST*> VariableDecls;
  std::vector<BaseAST*> StmtLists;

public:
  FunctionStmtAST(){};

  ~FunctionStmtAST();

  //関数に変数を追加する
  bool addVariableDeclaration(VariableDeclAST *vdecl);

  //関数にステートメントを追加する
  bool addStatement(BaseAST *stmt){StmtLists.push_back(stmt);return true;}

  //i番目の変数を取得する
  VariableDeclAST *getVariableDecl(int i){
    if(i < VariableDecls.size()){
      return VariableDecls.at(i);
    }
    else{
      return NULL;
    }
  };

  //i番目のステートメントを取得する
  BaseAST *getStatement(int i){
    if(i < StmtLists.size()){
      return StmtLists.at(i);
    }
    else{
      return NULL;
    }
  };
};

#endif