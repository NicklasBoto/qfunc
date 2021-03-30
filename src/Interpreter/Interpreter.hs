{-# language LambdaCase #-}

module Interpreter.Interpreter where

import System.IO ()

import qualified Data.Map as M
import Control.Monad.Except
    ( MonadTrans(lift), ExceptT, MonadError(throwError), runExceptT )
import Control.Monad.Reader ()
import Data.List ()
import Control.Monad.Identity ()
import qualified FunQ as Q
import Control.Monad.State ()
import Parser.Abs as Abs
    ( Gate(GS, GH, GX, GY, GZ, GI, GT, GCNOT, GTOF, GSWP, GFRDK),
      Bit(BOne, BZero),
      Program )
import qualified AST.AST as A

-- TODO:
-- test suite; i princip klart, men borde skriva lite större testprogram (likt teleport)
-- generell run gate (för att få med quantum fourier, genom Runnable TypeClass ex)

-- När vi tycker interpreter är klar! 
-- main driver: egen fil? turtle och haskelline? 

-- Nice to Have:
-- let user define custom gates (needs syntax for gate definition, type checking of arbitrary gate and evaluation of it)


data Error
    = NotFunction String
    | NoMainFunction String
    | NotApplied String
    | Fail String
    | IndexTooLarge String
    | ShowX12 String
     deriving Show

type Sig = M.Map String A.Term

type Eval a = ExceptT Error Q.QM a

data Env = Env {
      values    :: [Value]
    , functions :: Sig
}

instance Show Value where
    show (VBit b)    = show b
    show (VTup bs)   = show bs
    show (VQBit q)   = show q
    show VUnit       = "*"
    show (VFunc _ t) = "Function " ++ show t

-- Main function in interpreter (which we export)
interpret :: [A.Function] -> Eval Value
interpret fs = do
    -- Create environment 
    let env = createEnv fs
    -- Eval main function
    mainTerm <- getMainTerm env
    -- Return the return value from main
    eval env mainTerm

-- | Creates an environment from a list of functions. 
createEnv :: [A.Function] -> Env
createEnv fs = Env { functions = M.fromList [(s, t) | (A.Func s _ t) <- fs],
                            values = []}

getMainTerm :: Env -> Eval A.Term
getMainTerm env = case M.lookup "main" (functions env) of
    Just term -> return term
    Nothing   -> throwError $ NoMainFunction "Main function not defined"

data Value
    = VBit Q.Bit
    | VQBit Q.QBit
    | VUnit
    | VTup [Value]
    | VFunc [Value] A.Term

eval :: Env -> A.Term -> Eval Value
eval env = \case
    A.Idx j -> do
        if fromIntegral j >= length (values env) then do
            throwError $ IndexTooLarge $ "Index " ++ show j ++ " too large, Values=" ++ concat (map show (values env))
         else do
             return $ values env !! (fromIntegral j)

    A.Fun s -> case M.lookup s (functions env) of
        Just t  -> eval env t
        Nothing -> throwError $ NotFunction $ "Function " ++ show s ++ " is not defined"

    A.Bit BZero -> return $ VBit 0
    A.Bit BOne -> return $ VBit 1

    A.Tup bs -> VTup <$> mapM (eval env) bs

    A.App (A.Gate g) q -> case g of
         Abs.GH    -> runGate  Q.hadamard q env
         Abs.GX    -> runGate  Q.pauliX q env
         Abs.GY    -> runGate  Q.pauliY q env
         Abs.GZ    -> runGate  Q.pauliZ q env
         Abs.GI    -> runGate  Q.identity q env
         Abs.GT    -> runGate  Q.tdagger q env
         Abs.GS    -> runGate  Q.phase q env
         Abs.GCNOT -> run2Gate Q.cnot q env
         Abs.GTOF  -> run3Gate Q.toffoli q env
         Abs.GSWP  -> run2Gate Q.swap q env
         Abs.GFRDK -> run3Gate Q.fredkin q env
        -- GGate GateIdent
        --  , phasePi8
        --  , urot
        --  , crot
        --  , qft

        -- typeclass runnable, ta in gate och a, spotta ut QM a
        -- kan definiera olika fel

    A.App A.New b -> do
        VBit b' <- eval env b
        q <- lift $ Q.new b'
        return $ VQBit q

    A.App A.Meas q -> do
        VQBit q' <- eval env q
        b <- lift $ Q.measure q'
        return $ VBit b

    A.App e1 e2 -> do
        v2 <- eval env e2
        -- (lift . Q.io . print) $ "v2: " ++ show v2
        VFunc v1 a <- eval env e1
        -- (lift . Q.io . print) $ "a: " ++ show a
        eval env{ values = v2 : v1 ++ values env} a

    A.IfEl bit l r -> do
        VBit b <- eval env bit
        eval env $ if b == 1 then l else r

    A.Let eq inn -> do
         VTup [x1, x2] <- eval env eq
         eval env{ values = x2 : x1 : values env } inn

    A.Abs e  -> return $ VFunc (values env) e

    A.Void   -> return VUnit

    A.Gate g -> throwError $ NotApplied $ "Gate " ++ show g ++ " must be applied to something"

    A.New    -> throwError $ NotApplied "New must be applied to something"

    A.Meas   -> throwError $ NotApplied "Meas must be applied to something"

printE :: Show a => a -> Eval ()
printE = (lift . Q.io . putStrLn . show)

tuple :: Read a => [Q.QBit] -> a
tuple lst = read $ "(" ++ (init . tail . show) lst  ++ ")" 

runGate :: (Q.QBit -> Q.QM Q.QBit) -> A.Term -> Env -> Eval Value
runGate g q env = do
    VQBit q' <- eval env q
    VQBit <$> lift (g q')

run2Gate :: ((Q.QBit, Q.QBit) -> Q.QM (Q.QBit, Q.QBit)) -> A.Term -> Env -> Eval Value
run2Gate g q env = do
    VTup [VQBit a, VQBit b] <- eval env q
    res <- lift $ g (a,b)
    return $ VTup (tupToList res)
        where tupToList (a,b) = [VQBit a,VQBit b]

run3Gate :: ((Q.QBit, Q.QBit, Q.QBit) -> Q.QM (Q.QBit, Q.QBit, Q.QBit)) -> A.Term -> Env -> Eval Value
run3Gate g q env = do
    VTup [VQBit a, VQBit b, VQBit c] <- eval env q
    res <- lift $ g (a,b,c)
    return $ VTup (tupToList res)
        where tupToList (a,b,c) = [VQBit a, VQBit b, VQBit c]


