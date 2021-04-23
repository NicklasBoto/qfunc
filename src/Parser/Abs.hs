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
    | TLet LetVar [LetVar] Term Term
    | TLamb Lambda FunVar Type Term
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data LetVar = LVar Var
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Tup = Tuple Term [Term]
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Bit = BBit Integer
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data FunDec = FDecl FunVar Type Function
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Function = FDef Var [Arg] Term
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Arg = FArg Var
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Type
    = TypeBit
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
    | GQFT Integer
    | GQFTI Integer
    | GCR
    | GCRD
    | GCR2
    | GCR2D
    | GCR3
    | GCR3D
    | GCR4
    | GCR4D
    | GCR5
    | GCR5D
    | GCR8
    | GCR8D
    | GGate GateIdent
  deriving (C.Eq, C.Ord, C.Show, C.Read)

