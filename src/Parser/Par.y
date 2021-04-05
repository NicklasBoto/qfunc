-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module Parser.Par where
import Parser.Abs
import Parser.Lex
import Parser.ErrM

}

%name pProgram Program
%name pTerm3 Term3
%name pTerm2 Term2
%name pTerm1 Term1
%name pTerm Term
%name pLetVar LetVar
%name pListLetVar ListLetVar
%name pTup Tup
%name pListTerm ListTerm
%name pBit Bit
%name pFunDec FunDec
%name pListFunDec ListFunDec
%name pFunction Function
%name pArg Arg
%name pListArg ListArg
%name pType2 Type2
%name pType1 Type1
%name pType Type
%name pGate Gate
-- no lexer declaration
%monad { Err } { thenM } { returnM }
%tokentype {Token}
%token
  ' ' { PT _ (TS _ 1) }
  '!' { PT _ (TS _ 2) }
  '(' { PT _ (TS _ 3) }
  ')' { PT _ (TS _ 4) }
  '*' { PT _ (TS _ 5) }
  ',' { PT _ (TS _ 6) }
  '-o' { PT _ (TS _ 7) }
  '.' { PT _ (TS _ 8) }
  '0' { PT _ (TS _ 9) }
  '1' { PT _ (TS _ 10) }
  '=' { PT _ (TS _ 11) }
  '><' { PT _ (TS _ 12) }
  'Bit' { PT _ (TS _ 13) }
  'CNOT' { PT _ (TS _ 14) }
  'FREDKIN' { PT _ (TS _ 15) }
  'H' { PT _ (TS _ 16) }
  'I' { PT _ (TS _ 17) }
  'QBit' { PT _ (TS _ 18) }
  'QFT' { PT _ (TS _ 19) }
  'S' { PT _ (TS _ 20) }
  'SWAP' { PT _ (TS _ 21) }
  'T' { PT _ (TS _ 22) }
  'TOFFOLI' { PT _ (TS _ 23) }
  'X' { PT _ (TS _ 24) }
  'Y' { PT _ (TS _ 25) }
  'Z' { PT _ (TS _ 26) }
  'else' { PT _ (TS _ 27) }
  'if' { PT _ (TS _ 28) }
  'in' { PT _ (TS _ 29) }
  'let' { PT _ (TS _ 30) }
  'then' { PT _ (TS _ 31) }
  L_FunVar { PT _ (T_FunVar $$) }
  L_Var { PT _ (T_Var $$) }
  L_GateIdent { PT _ (T_GateIdent $$) }
  L_Lambda { PT _ (T_Lambda $$) }

%%

FunVar :: { FunVar}
FunVar  : L_FunVar { FunVar ($1)}

Var :: { Var}
Var  : L_Var { Var ($1)}

GateIdent :: { GateIdent}
GateIdent  : L_GateIdent { GateIdent ($1)}

Lambda :: { Lambda}
Lambda  : L_Lambda { Lambda ($1)}

Program :: { Program }
Program : ListFunDec { Parser.Abs.PDef (reverse $1) }
Term3 :: { Term }
Term3 : Var { Parser.Abs.TVar $1 }
      | Bit { Parser.Abs.TBit $1 }
      | Gate { Parser.Abs.TGate $1 }
      | Tup { Parser.Abs.TTup $1 }
      | '*' { Parser.Abs.TStar }
      | '(' Term ')' { $2 }
Term2 :: { Term }
Term2 : Term2 Term3 { Parser.Abs.TApp $1 $2 } | Term3 { $1 }
Term1 :: { Term }
Term1 : 'if' Term2 'then' Term 'else' Term { Parser.Abs.TIfEl $2 $4 $6 }
      | 'let' '(' LetVar ',' ListLetVar ')' '=' Term 'in' Term { Parser.Abs.TLet $3 $5 $8 $10 }
      | Lambda Var '.' Term { Parser.Abs.TLamb $1 $2 $4 }
      | Term2 { $1 }
Term :: { Term }
Term : Term1 { $1 }
LetVar :: { LetVar }
LetVar : Var { Parser.Abs.LVar $1 }
ListLetVar :: { [LetVar] }
ListLetVar : LetVar { (:[]) $1 }
           | LetVar ',' ListLetVar { (:) $1 $3 }
Tup :: { Tup }
Tup : '(' Term ',' ListTerm ')' { Parser.Abs.Tuple $2 $4 }
ListTerm :: { [Term] }
ListTerm : Term { (:[]) $1 } | Term ',' ListTerm { (:) $1 $3 }
Bit :: { Bit }
Bit : '0' { Parser.Abs.BZero } | '1' { Parser.Abs.BOne }
FunDec :: { FunDec }
FunDec : FunVar Type Function { Parser.Abs.FDecl $1 $2 $3 }
ListFunDec :: { [FunDec] }
ListFunDec : {- empty -} { [] }
           | ListFunDec FunDec { flip (:) $1 $2 }
Function :: { Function }
Function : Var ListArg '=' Term { Parser.Abs.FDef $1 $2 $4 }
Arg :: { Arg }
Arg : Var { Parser.Abs.FArg $1 }
ListArg :: { [Arg] }
ListArg : {- empty -} { [] }
        | Arg { (:[]) $1 }
        | Arg ' ' ListArg { (:) $1 $3 }
Type2 :: { Type }
Type2 : Var { Parser.Abs.TypeVar $1 }
      | 'Bit' { Parser.Abs.TypeBit }
      | 'QBit' { Parser.Abs.TypeQbit }
      | 'T' { Parser.Abs.TypeVoid }
      | '!' Type2 { Parser.Abs.TypeDup $2 }
      | '(' Type ')' { $2 }
Type1 :: { Type }
Type1 : Type2 '><' Type1 { Parser.Abs.TypeTens $1 $3 }
      | Type2 '-o' Type1 { Parser.Abs.TypeFunc $1 $3 }
      | Type2 { $1 }
Type :: { Type }
Type : Type1 { $1 }
Gate :: { Gate }
Gate : 'H' { Parser.Abs.GH }
     | 'X' { Parser.Abs.GX }
     | 'Y' { Parser.Abs.GY }
     | 'Z' { Parser.Abs.GZ }
     | 'I' { Parser.Abs.GI }
     | 'S' { Parser.Abs.GS }
     | 'T' { Parser.Abs.GT }
     | 'CNOT' { Parser.Abs.GCNOT }
     | 'TOFFOLI' { Parser.Abs.GTOF }
     | 'SWAP' { Parser.Abs.GSWP }
     | 'FREDKIN' { Parser.Abs.GFRDK }
     | 'QFT' { Parser.Abs.GQFT }
     | GateIdent { Parser.Abs.GGate $1 }
{

returnM :: a -> Err a
returnM = return

thenM :: Err a -> (a -> Err b) -> Err b
thenM = (>>=)

happyError :: [Token] -> Err a
happyError ts =
  Bad $ "syntax error at " ++ tokenPos ts ++
  case ts of
    []      -> []
    [Err _] -> " due to lexer error"
    t:_     -> " before `" ++ id(prToken t) ++ "'"

myLexer = tokens
}

