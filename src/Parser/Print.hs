{-# LANGUAGE CPP #-}
#if __GLASGOW_HASKELL__ <= 708
{-# LANGUAGE OverlappingInstances #-}
#endif
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}

-- | Pretty-printer for Parser.
--   Generated by the BNF converter.

module Parser.Print where

import qualified Parser.Abs
import Data.Char

-- | The top-level printing method.

printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    [";"]        -> showChar ';'
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : ts@(p:_) | closingOrPunctuation p -> showString t . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i     = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t s =
    case (all isSpace t' || t' == "!", null spc, null rest) of
      (True , _   , True ) -> []              -- remove trailing space
      (False, _   , True ) -> t'              -- remove trailing space
      (False, True, False) -> t' ++ ' ' : s   -- add space if none
      _                    -> t' ++ s
    where
      t'          = showString t []
      (spc, rest) = span isSpace s

  closingOrPunctuation :: String -> Bool
  closingOrPunctuation [c] = c `elem` closerOrPunct
  closingOrPunctuation _   = False

  closerOrPunct :: String
  closerOrPunct = ")],;"

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- | The printer class does the job.

class Print a where
  prt :: Int -> a -> Doc
  prtList :: Int -> [a] -> Doc
  prtList i = concatD . map (prt i)

instance {-# OVERLAPPABLE #-} Print a => Print [a] where
  prt = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j < i then parenth else id

instance Print Integer where
  prt _ x = doc (shows x)

instance Print Double where
  prt _ x = doc (shows x)

instance Print Parser.Abs.FunVar where
  prt _ (Parser.Abs.FunVar i) = doc $ showString $ i

instance Print Parser.Abs.Var where
  prt _ (Parser.Abs.Var i) = doc $ showString $ i

instance Print Parser.Abs.GateIdent where
  prt _ (Parser.Abs.GateIdent i) = doc $ showString $ i

instance Print Parser.Abs.Lambda where
  prt _ (Parser.Abs.Lambda i) = doc $ showString $ "λ"

instance Print Parser.Abs.Program where
  prt i e = case e of
    Parser.Abs.PDef fundecs -> prPrec i 0 (concatD [prt 0 fundecs])

instance Print Parser.Abs.Term where
  prt i e = case e of
    Parser.Abs.TVar var -> prPrec i 3 (concatD [prt 0 var])
    Parser.Abs.TBit bit -> prPrec i 3 (concatD [prt 0 bit])
    Parser.Abs.TGate gate -> prPrec i 3 (concatD [prt 0 gate])
    Parser.Abs.TTup tup -> prPrec i 3 (concatD [prt 0 tup])
    Parser.Abs.TStar -> prPrec i 3 (concatD [doc (showString "*")])
    Parser.Abs.TDolr term1 term2 -> prPrec i 2 (concatD [prt 2 term1, doc (showString "$"), prt 3 term2])
    Parser.Abs.TApp term1 term2 -> prPrec i 2 (concatD [prt 2 term1, prt 3 term2])
    Parser.Abs.TIfEl term1 term2 term3 -> prPrec i 1 (concatD [doc (showString "if"), prt 2 term1, doc (showString "then"), prt 0 term2, doc (showString "else"), prt 0 term3])
    Parser.Abs.TLet letvar letvars term1 term2 -> prPrec i 1 (concatD [doc (showString "let"), doc (showString "("), prt 0 letvar, doc (showString ","), prt 0 letvars, doc (showString ")"), doc (showString "="), prt 0 term1, doc (showString "in"), prt 0 term2])
    Parser.Abs.TLamb lambda funvar type_ term -> prPrec i 1 (concatD [prt 0 lambda, prt 0 funvar, doc (showString ":"), prt 0 type_, doc (showString "."), prt 0 term])
  prtList _ [x] = concatD [prt 0 x]
  prtList _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Parser.Abs.LetVar where
  prt i e = case e of
    Parser.Abs.LVar var -> prPrec i 0 (concatD [prt 0 var])
  prtList _ [x] = concatD [prt 0 x]
  prtList _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print [Parser.Abs.LetVar] where
  prt = prtList

instance Print Parser.Abs.Tup where
  prt i e = case e of
    Parser.Abs.Tuple term terms -> prPrec i 0 (concatD [doc (showString "⟨"), prt 0 term, doc (showString ","), prt 0 terms, doc (showString "⟩")])

instance Print [Parser.Abs.Term] where
  prt = prtList

instance Print Parser.Abs.Bit where
  prt i e = case e of
    Parser.Abs.BBit n -> prPrec i 0 (concatD [prt 0 n])

instance Print Parser.Abs.FunDec where
  prt i e = case e of
    Parser.Abs.FDecl funvar type_ function -> prPrec i 0 (concatD [prt 0 funvar, prt 0 type_, prt 0 function])
  prtList _ [] = concatD []
  prtList _ (x:xs) = concatD [prt 0 x, prt 0 xs]

instance Print [Parser.Abs.FunDec] where
  prt = prtList

instance Print Parser.Abs.Function where
  prt i e = case e of
    Parser.Abs.FDef var args term -> prPrec i 0 (concatD [prt 0 var, prt 0 args, doc (showString "="), prt 0 term])

instance Print Parser.Abs.Arg where
  prt i e = case e of
    Parser.Abs.FArg var -> prPrec i 0 (concatD [prt 0 var])
  prtList _ [] = concatD []
  prtList _ (x:xs) = concatD [prt 0 x, doc (showString " "), prt 0 xs]

instance Print [Parser.Abs.Arg] where
  prt = prtList

instance Print Parser.Abs.Type where
  prt i e = case e of
    Parser.Abs.TypeBit -> prPrec i 2 (concatD [doc (showString "Bit")])
    Parser.Abs.TypeQbit -> prPrec i 2 (concatD [doc (showString "QBit")])
    Parser.Abs.TypeUnit -> prPrec i 2 (concatD [doc (showString "⊤")])
    Parser.Abs.TypeDup type_ -> prPrec i 2 (concatD [doc (showString "!"), prt 2 type_])
    Parser.Abs.TypeTens type_1 type_2 -> prPrec i 1 (concatD [prt 2 type_1, doc (showString "⊗"), prt 1 type_2])
    Parser.Abs.TypeFunc type_1 type_2 -> prPrec i 1 (concatD [prt 2 type_1, doc (showString "⊸"), prt 1 type_2])

instance Print Parser.Abs.Gate where
  prt i e = case e of
    Parser.Abs.GH -> prPrec i 0 (concatD [doc (showString "H")])
    Parser.Abs.GX -> prPrec i 0 (concatD [doc (showString "X")])
    Parser.Abs.GY -> prPrec i 0 (concatD [doc (showString "Y")])
    Parser.Abs.GZ -> prPrec i 0 (concatD [doc (showString "Z")])
    Parser.Abs.GI -> prPrec i 0 (concatD [doc (showString "I")])
    Parser.Abs.GS -> prPrec i 0 (concatD [doc (showString "S")])
    Parser.Abs.GT -> prPrec i 0 (concatD [doc (showString "T")])
    Parser.Abs.GCNOT -> prPrec i 0 (concatD [doc (showString "CNOT")])
    Parser.Abs.GTOF -> prPrec i 0 (concatD [doc (showString "TOFFOLI")])
    Parser.Abs.GSWP -> prPrec i 0 (concatD [doc (showString "SWAP")])
    Parser.Abs.GFRDK -> prPrec i 0 (concatD [doc (showString "FREDKIN")])
    Parser.Abs.GIdent gateident -> prPrec i 0 (concatD [prt 0 gateident])

