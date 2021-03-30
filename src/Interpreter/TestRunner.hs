module Interpreter.TestRunner where

{-# LANGUAGE CPP               #-}
{-# LANGUAGE ViewPatterns      #-}

import Interpreter.Main

import Control.Applicative hiding (empty)
import Control.Monad

import Data.Char
import Data.Function
import Data.IORef
import qualified Data.List as List
import Data.Maybe
import Data.Monoid

testPath :: String -> String
testPath testName = "src/Interpreter/test-suite/" ++ testName

goodTests :: [(FilePath, String)]
goodTests = [
    (testPath "cnot.fq", "0"),
    (testPath "equals.fq", "1"),
    (testPath "id.fq", "1"),
    (testPath "let-tup-q.fq", "0"),
    (testPath "let-tup.fq", "0"),
    (testPath "pauliX.fq", "1"),     
    (testPath "plus.fq", "0"),
    (testPath "second-q.fq", "0"),
    (testPath "second.fq", "1"),
    (testPath "third.fq", "1"),
    (testPath "seventh.fq", "0"),
    (testPath "teleport.fq", "1")
    ]

-- runTests :: IO ()
-- runTests = do 
--     mapM_ runTest goodTests

-- runTest :: (FilePath, String) -> Int -> (Int, IO ())
-- runTest (path, expectedValue) = do 
--     res <- run path
--     if show res == expectedValue then putStrLn $ "Test for " ++ show path ++ " successful!" ++ "\n" 
--     else putStrLn $ "Test for " ++ show path ++ " failed! Expected " ++ expectedValue ++ " but got " ++ show res ++ "\n"


runTests' :: IO ()
runTests' = do 
    --mapM_ runTest goodTests
    correct <- foldr runTest' (return 0) goodTests
    putStrLn $ "Succesful tests " ++ show correct ++ "/" ++ show (length goodTests)
    --return ()

-- a = (FilePath,String), b = IO Int 
runTest' :: (FilePath, String) -> IO Int -> IO Int
runTest' (path, expectedValue) b = do 
    res <- run path
    acc <- b
    if show res == expectedValue then do 
        putStrLn $ "Test for " ++ show path ++ " successful!" ++ "\n" 
        return $ acc + 1
    else do 
        putStrLn $ "Test for " ++ show path ++ " failed! Expected " ++ expectedValue ++ " but got " ++ show res ++ "\n"
        return acc