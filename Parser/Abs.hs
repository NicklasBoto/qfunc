-- Haskell data types for the abstract syntax.
-- Generated by the BNF converter.

{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Parser.Abs where

import Prelude (Char, Double, Integer, String)
import qualified Prelude as C (Eq, Ord, Show, Read)
import qualified Data.String

newtype FunVar = FunVar String
  deriving (C.Eq, C.Ord, C.Show, C.Read, Data.String.IsString)

newtype Var = Var String
  deriving (C.Eq, C.Ord, C.Show, C.Read, Data.String.IsString)

newtype GateIdent = GateIdent String
  deriving (C.Eq, C.Ord, C.Show, C.Read, Data.String.IsString)

newtype Lambda = Lambda String
  deriving (C.Eq, C.Ord, C.Show, C.Read, Data.String.IsString)

data Program = PDef [FunDec]
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Term
    = TVar Var
    | TBit Bit
    | TGate Gate
    | TTup Tup
    | TStar
    | TApp Term Term
    | TIfEl Term Term Term
    | TLet Var Var Term Term
    | TLamb Lambda Var Term
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Tup = Tuple Term [Term]
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Bit = BZero | BOne
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data FunDec = FDecl FunVar Type Function
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Function = FDef Var [Arg] Term
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Arg = FArg Var
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Type
    = TypeVar Var
    | TypeBit
    | TypeQbit
    | TypeVoid
    | TypeDup Type
    | TypeTens Type Type
    | TypeFunc Type Type
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Gate
    = GH
    | GX
    | GY
    | GZ
    | GI
    | GS
    | GT
    | GCNOT
    | GTOF
    | GSWP
    | GFRDK
    | GGate GateIdent
  deriving (C.Eq, C.Ord, C.Show, C.Read)
