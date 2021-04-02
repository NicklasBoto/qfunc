-- Haskell module generated by the BNF converter

module Parser.Skel where

import qualified Parser.Abs

type Err = Either String
type Result = Err String

failure :: Show a => a -> Result
failure x = Left $ "Undefined case: " ++ show x

transFunVar :: Parser.Abs.FunVar -> Result
transFunVar x = case x of
  Parser.Abs.FunVar string -> failure x
transVar :: Parser.Abs.Var -> Result
transVar x = case x of
  Parser.Abs.Var string -> failure x
transGateIdent :: Parser.Abs.GateIdent -> Result
transGateIdent x = case x of
  Parser.Abs.GateIdent string -> failure x
transLambda :: Parser.Abs.Lambda -> Result
transLambda x = case x of
  Parser.Abs.Lambda string -> failure x
transProgram :: Parser.Abs.Program -> Result
transProgram x = case x of
  Parser.Abs.PDef fundecs -> failure x
transTerm :: Parser.Abs.Term -> Result
transTerm x = case x of
  Parser.Abs.TVar var -> failure x
  Parser.Abs.TBit bit -> failure x
  Parser.Abs.TGate gate -> failure x
  Parser.Abs.TTup tup -> failure x
  Parser.Abs.TStar -> failure x
  Parser.Abs.TApp term1 term2 -> failure x
  Parser.Abs.TIfEl term1 term2 term3 -> failure x
  Parser.Abs.TLet var1 var2 term1 term2 -> failure x
  Parser.Abs.TLamb lambda var term -> failure x
transTup :: Parser.Abs.Tup -> Result
transTup x = case x of
  Parser.Abs.Tuple term terms -> failure x
transBit :: Parser.Abs.Bit -> Result
transBit x = case x of
  Parser.Abs.BZero -> failure x
  Parser.Abs.BOne -> failure x
transFunDec :: Parser.Abs.FunDec -> Result
transFunDec x = case x of
  Parser.Abs.FDecl funvar type_ function -> failure x
transFunction :: Parser.Abs.Function -> Result
transFunction x = case x of
  Parser.Abs.FDef var args term -> failure x
transArg :: Parser.Abs.Arg -> Result
transArg x = case x of
  Parser.Abs.FArg var -> failure x
transType :: Parser.Abs.Type -> Result
transType x = case x of
  Parser.Abs.TypeVar var -> failure x
  Parser.Abs.TypeBit -> failure x
  Parser.Abs.TypeQbit -> failure x
  Parser.Abs.TypeVoid -> failure x
  Parser.Abs.TypeDup type_ -> failure x
  Parser.Abs.TypeTens type_1 type_2 -> failure x
  Parser.Abs.TypeFunc type_1 type_2 -> failure x
transGate :: Parser.Abs.Gate -> Result
transGate x = case x of
  Parser.Abs.GH -> failure x
  Parser.Abs.GX -> failure x
  Parser.Abs.GY -> failure x
  Parser.Abs.GZ -> failure x
  Parser.Abs.GI -> failure x
  Parser.Abs.GS -> failure x
  Parser.Abs.GT -> failure x
  Parser.Abs.GCNOT -> failure x
  Parser.Abs.GTOF -> failure x
  Parser.Abs.GSWP -> failure x
  Parser.Abs.GFRDK -> failure x
  Parser.Abs.GQFT -> failure x
  Parser.Abs.GGate gateident -> failure x

