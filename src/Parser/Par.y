-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module Parser.Par
  ( happyError
  , myLexer
  , pProgram
  , pTerm3
  , pTerm2
  , pTerm1
  , pTerm
  , pLetVar
  , pListLetVar
  , pTup
  , pListTerm
  , pBit
  , pFunDec
  , pListFunDec
  , pFunction
  , pArg
  , pListArg
  , pType2
  , pType1
  , pType
  , pGate
  ) where
import qualified Parser.Abs
import Parser.Lex
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
%monad { Either String } { (>>=) } { return }
%tokentype {Token}
%token
  '!' { PT _ (TS _ 1) }
  '(' { PT _ (TS _ 2) }
  ')' { PT _ (TS _ 3) }
  '*' { PT _ (TS _ 4) }
  ',' { PT _ (TS _ 5) }
  '-o' { PT _ (TS _ 6) }
  '.' { PT _ (TS _ 7) }
  '=' { PT _ (TS _ 8) }
  '><' { PT _ (TS _ 9) }
  'Bit' { PT _ (TS _ 10) }
  'CNOT' { PT _ (TS _ 11) }
  'FREDKIN' { PT _ (TS _ 12) }
  'H' { PT _ (TS _ 13) }
  'I' { PT _ (TS _ 14) }
  'QBit' { PT _ (TS _ 15) }
  'S' { PT _ (TS _ 16) }
  'SWAP' { PT _ (TS _ 17) }
  'T' { PT _ (TS _ 18) }
  'TOFFOLI' { PT _ (TS _ 19) }
  'X' { PT _ (TS _ 20) }
  'Y' { PT _ (TS _ 21) }
  'Z' { PT _ (TS _ 22) }
  'else' { PT _ (TS _ 23) }
  'if' { PT _ (TS _ 24) }
  'in' { PT _ (TS _ 25) }
  'let' { PT _ (TS _ 26) }
  'then' { PT _ (TS _ 27) }
  L_integ  { PT _ (TI $$) }
  L_FunVar { PT _ (T_FunVar $$) }
  L_Var { PT _ (T_Var $$) }
  L_GateIdent { PT _ (T_GateIdent $$) }
  L_Lambda { PT _ (T_Lambda $$) }

%%

Integer :: { Integer }
Integer  : L_integ  { (read ($1)) :: Integer }

FunVar :: { Parser.Abs.FunVar}
FunVar  : L_FunVar { Parser.Abs.FunVar $1 }

Var :: { Parser.Abs.Var}
Var  : L_Var { Parser.Abs.Var $1 }

GateIdent :: { Parser.Abs.GateIdent}
GateIdent  : L_GateIdent { Parser.Abs.GateIdent $1 }

Lambda :: { Parser.Abs.Lambda}
Lambda  : L_Lambda { Parser.Abs.Lambda $1 }

Program :: { Parser.Abs.Program }
Program : ListFunDec { Parser.Abs.PDef $1 }

Term3 :: { Parser.Abs.Term }
Term3 : Var { Parser.Abs.TVar $1 }
      | Bit { Parser.Abs.TBit $1 }
      | Gate { Parser.Abs.TGate $1 }
      | Tup { Parser.Abs.TTup $1 }
      | '*' { Parser.Abs.TStar }
      | '(' Term ')' { $2 }

Term2 :: { Parser.Abs.Term }
Term2 : Term2 Term3 { Parser.Abs.TApp $1 $2 } | Term3 { $1 }

Term1 :: { Parser.Abs.Term }
Term1 : 'if' Term 'then' Term 'else' Term { Parser.Abs.TIfEl $2 $4 $6 }
      | 'let' '(' LetVar ',' ListLetVar ')' '=' Term 'in' Term { Parser.Abs.TLet $3 $5 $8 $10 }
      | Lambda FunVar Type '.' Term { Parser.Abs.TLamb $1 $2 $3 $5 }
      | Term2 { $1 }

Term :: { Parser.Abs.Term }
Term : Term1 { $1 }

LetVar :: { Parser.Abs.LetVar }
LetVar : Var { Parser.Abs.LVar $1 }

ListLetVar :: { [Parser.Abs.LetVar] }
ListLetVar : LetVar { (:[]) $1 }
           | LetVar ',' ListLetVar { (:) $1 $3 }

Tup :: { Parser.Abs.Tup }
Tup : '(' Term ',' ListTerm ')' { Parser.Abs.Tuple $2 $4 }

ListTerm :: { [Parser.Abs.Term] }
ListTerm : Term { (:[]) $1 } | Term ',' ListTerm { (:) $1 $3 }

Bit :: { Parser.Abs.Bit }
Bit : Integer { Parser.Abs.BBit $1 }

FunDec :: { Parser.Abs.FunDec }
FunDec : FunVar Type Function { Parser.Abs.FDecl $1 $2 $3 }

ListFunDec :: { [Parser.Abs.FunDec] }
ListFunDec : {- empty -} { [] } | FunDec ListFunDec { (:) $1 $2 }

Function :: { Parser.Abs.Function }
Function : Var ListArg '=' Term { Parser.Abs.FDef $1 $2 $4 }

Arg :: { Parser.Abs.Arg }
Arg : Var { Parser.Abs.FArg $1 }

ListArg :: { [Parser.Abs.Arg] }
ListArg : {- empty -} { [] } | Arg ListArg { (:) $1 $2 }

Type2 :: { Parser.Abs.Type }
Type2 : 'Bit' { Parser.Abs.TypeBit }
      | 'QBit' { Parser.Abs.TypeQbit }
      | 'T' { Parser.Abs.TypeUnit }
      | '!' Type2 { Parser.Abs.TypeDup $2 }
      | '(' Type ')' { $2 }

Type1 :: { Parser.Abs.Type }
Type1 : Type2 '><' Type1 { Parser.Abs.TypeTens $1 $3 }
      | Type2 '-o' Type1 { Parser.Abs.TypeFunc $1 $3 }
      | Type2 { $1 }

Type :: { Parser.Abs.Type }
Type : Type1 { $1 }

Gate :: { Parser.Abs.Gate }
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
     | GateIdent { Parser.Abs.GIdent $1 }
{

happyError :: [Token] -> Either String a
happyError ts = Left $
  "syntax error at " ++ tokenPos ts ++
  case ts of
    []      -> []
    [Err _] -> " due to lexer error"
    t:_     -> " before `" ++ (prToken t) ++ "'"

myLexer = tokens
}

