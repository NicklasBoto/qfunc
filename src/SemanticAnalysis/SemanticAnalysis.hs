{-# language LambdaCase #-}

module SemanticAnalysis.SemanticAnalysis where

import qualified FunQ as Q
import qualified AST.AST as A
import Parser.Par (pProgram, myLexer)
import qualified Interpreter.Interpreter as I
import System.Console.Haskeline
import Control.Monad.Except
    ( MonadIO(liftIO),
      MonadError(throwError),
      ExceptT(..),
      mapExceptT,
      runExceptT,
      withExceptT, replicateM )
import Data.Bifunctor ( Bifunctor(bimap) )
import Control.Exception (try)
import qualified Type.HM as HM
import Data.List
import Parser.Abs
import qualified Data.Set as Set

data SemanticError 
  = FunNameMismatch String
  | NoMainFunction String
  | DupFun String
  | UnknownGate String
  | TooManyArguments String
    -- deriving Show

instance Show SemanticError where
  show (FunNameMismatch e) =
    "semantic error:\n" ++ show e

  show (NoMainFunction e) =
    "syntax error:\n" ++ e

  show (DupFun e) =
    "type error:\n" ++ show e

  show (UnknownGate e) =
    "value error:\n" ++ show e

  show (TooManyArguments f) =
    "TooManyArguments: " ++ f

-- Refakturering
-- fs istället för p
-- koddupliceringen
-- collect all errors

semanticAnalysis :: Program -> Either SemanticError ()
semanticAnalysis (PDef fs) = do 
  funNameMatch fs
  mainDefined fs
  dupFun fs
  unknownGate fs
  onlyBits fs
  correctNumberOfArgs fs
  
funNameMatch :: [FunDec] -> Either SemanticError ()
funNameMatch fs = if null mismatches then Right () else Left $ FunNameMismatch $ "Mismatchig names in function declaration and definition for " ++ mismatches
  where mismatches = concat $ intersperse ", " $ check fs []
        check :: [FunDec] -> [String] -> [String]   
        check [] ms = ms
        check ((FDecl (FunVar s) _ (FDef (Var s') _ _)):fs) ms = if (funName' s) == s' then check fs ms else check fs (ms ++ [(funName' s)])  
        funName' :: String -> String 
        funName' s = takeUntil " " (takeUntil ":" s)
    

mainDefined :: [FunDec] -> Either SemanticError ()
mainDefined fs = if any isMain fs then Right () else Left $ NoMainFunction "No main function has been declared"
  where isMain f = funName f == "main"


dupFun :: [FunDec] -> Either SemanticError ()
dupFun fs = if null collectErrors then Right () else Left $ DupFun $ "Duplicate functions declarations for " ++ collectErrors
  where collectErrors = concat $ intersperse ", " $ check funNames []
        check :: [String] -> [String] -> [String]
        check []     errors = errors 
        check (f:fs) errors = if dup f && (not $ elem f fs) then check fs (f:errors) else check fs errors
        funNames = map funName fs
        dup :: String -> Bool
        dup f = length (filter (== f) funNames) > 1
        

-- gateIdent blir fail! 
unknownGate :: [FunDec] -> Either SemanticError ()
unknownGate fs = if null collectUnknownGates then Right () else Left $ UnknownGate $ collectUnknownGates ++ " are not predefined gates"
  where collectUnknownGates = concat $ intersperse ", " $ check fs []
        check :: [FunDec] -> [String] -> [String]
        check [] gs = gs
        check ((FDecl _ _ (FDef _ _ t)):fs) gs = check fs (gs ++ unknownGates t [])
        unknownGates :: Term -> [String] -> [String]
        unknownGates (TGate (GGate (GateIdent g))) gs = gs ++ [g]
        unknownGates (TApp t1 t2) gs                  = gs ++ unknownGates t1 [] ++ unknownGates t2 []
        unknownGates (TIfEl t1 t2 t3) gs              = gs ++ unknownGates t1 [] ++ unknownGates t2 [] ++ unknownGates t3 [] 
        unknownGates (TLet _ _ t1 t2) gs              = gs ++ unknownGates t1 [] ++ unknownGates t2 []
        unknownGates (TLamb _ _ t1) gs                = gs ++ unknownGates t1 []
        unknownGates _ gs                             = gs

-- Endast 0/1 (måste göra om grammar!)
onlyBits :: [FunDec] -> Either SemanticError ()
onlyBits fs = if null collectInvalidBits then Right () else Left $ UnknownGate $ "Expected value of bits to be 0 or 1 but got " ++ collectInvalidBits
  where collectInvalidBits = concat $ intersperse ", " $ check fs []
        check :: [FunDec] -> [String] -> [String]
        check [] gs = gs
        check ((FDecl _ _ (FDef _ _ t)):fs) gs = check fs (gs ++ invalidBit t [])
        invalidBit :: Term -> [String] -> [String]
        invalidBit (TBit (BBit n)) gs   = if not (n == 0 || n == 1) then show n : gs else gs
        invalidBit (TApp t1 t2) gs      = gs ++ invalidBit t1 [] ++ invalidBit t2 []
        invalidBit (TIfEl t1 t2 t3) gs  = gs ++ invalidBit t1 [] ++ invalidBit t2 [] ++ invalidBit t3 [] 
        invalidBit (TLet _ _ t1 t2) gs  = gs ++ invalidBit t1 [] ++ invalidBit t2 []
        invalidBit (TLamb _ _ t1) gs    = gs ++ invalidBit t1 []
        invalidBit _ gs                 = gs

-- antalet argument är samma eller fler som antalet typer - 1
correctNumberOfArgs :: [FunDec] -> Either SemanticError ()
correctNumberOfArgs fs = if null mismatches then Right () else Left $ TooManyArguments $ "Incorrect number of arguments for: " ++ mismatches
  where mismatches = concat $ intersperse "\n" $ check fs []
        check :: [FunDec] -> [String] -> [String]   
        check [] ms = ms
        check (f@(FDecl (FunVar s) _ (FDef (Var s') _ _)):fs) ms = if isValid f then check fs ms else check fs (errorMsg f : ms)  
        isValid :: FunDec -> Bool 
        isValid (FDecl _ t (FDef _ args _)) = length args < size t
        size :: Type -> Int 
        size (TypeFunc t1 t2) = size t1 + size t2
        size (TypeTens t1 t2) = size t1 + size t2
        size (TypeDup t)      = size t 
        size _                = 1
        errorMsg :: FunDec -> String 
        errorMsg f@(FDecl _ t (FDef _ args _)) = funName f ++ " has " ++ (show $ length args) ++ " arguments, but function takes only " ++ (show $ size t - 1) ++ " arguments."


-- borde funka
-- f : Bit -o Bit
-- f = id

-- borde inte funka
-- f : Bit
-- f x = 0

-- Utils
takeUntil :: String -> String -> String
takeUntil [] [] = []                           --don't need this
takeUntil xs [] = [] 
takeUntil [] ys = [] 
takeUntil xs (y:ys) = if isPrefixOf xs (y:ys)
                      then []
                      else y:(takeUntil xs (tail (y:ys)))

funName :: FunDec -> String 
funName (FDecl _ _ (FDef (Var s) _ _)) = s